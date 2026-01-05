#!/usr/bin/env python3
"""Extract iMessage text from attributedBody blobs"""

import sqlite3
import os
import re
import json
from datetime import datetime
from collections import defaultdict

# Database paths
IMESSAGE_DB = os.path.expanduser("~/Library/Messages/chat.db")
ADDRESSBOOK_DB = None

# Find address book
ab_path = os.path.expanduser("~/Library/Application Support/AddressBook")
for root, dirs, files in os.walk(ab_path):
    for f in files:
        if f == "AddressBook-v22.abcddb":
            ADDRESSBOOK_DB = os.path.join(root, f)
            break

# Chat identifiers for 9pm movie club
CHAT_IDS = ['chat53137152716289611', 'chat391035900966244623']

# 2025 timestamps (Apple Core Data format - seconds since 2001-01-01)
START_2025 = 757382400
END_2025 = 788918400

def extract_text_from_attributed_body(blob):
    """Extract readable text from NSAttributedString blob"""
    if not blob:
        return None

    try:
        # The text is stored after "NSString" marker, typically as UTF-8
        # Look for printable ASCII/UTF-8 sequences
        text = ""

        # Try to find the actual text content
        # It's usually after the streamtyped header
        if b'streamtyped' in blob:
            # Find the position after the header info
            start = blob.find(b'streamtyped')
            if start != -1:
                # Skip header, look for actual text
                chunk = blob[start+50:]

                # Extract printable characters
                current_text = []
                for byte in chunk:
                    if 32 <= byte <= 126 or byte in (10, 13):  # Printable ASCII + newlines
                        current_text.append(chr(byte))
                    elif current_text and len(current_text) > 3:
                        # Check if we have meaningful text
                        candidate = ''.join(current_text)
                        if not candidate.startswith('NS') and not 'class' in candidate.lower():
                            text = candidate
                            break
                        current_text = []
                    else:
                        current_text = []

        # Alternative: just grab sequences of printable chars
        if not text:
            decoded = blob.decode('utf-8', errors='ignore')
            # Find the longest sequence of normal text
            matches = re.findall(r'[\x20-\x7E\n\r]{5,}', decoded)
            for m in matches:
                # Skip internal macOS strings
                if not any(x in m for x in ['NSString', 'NSDict', 'NSValue', 'NSNumber', 'class', 'streamtyped', 'bplist', 'NSMutable']):
                    if len(m) > len(text):
                        text = m

        # Try hex decoding approach
        if not text or len(text) < 5:
            hex_str = blob.hex()
            # Look for UTF-8 text patterns
            try:
                # Find reasonable text between markers
                decoded_parts = []
                for i in range(0, len(hex_str)-1, 2):
                    byte_val = int(hex_str[i:i+2], 16)
                    if 32 <= byte_val <= 126:
                        decoded_parts.append(chr(byte_val))
                    elif decoded_parts and len(''.join(decoded_parts)) > 5:
                        candidate = ''.join(decoded_parts)
                        if not any(x in candidate for x in ['NS', 'bplist', 'stream']):
                            if len(candidate) > len(text or ''):
                                text = candidate
                        decoded_parts = []
                    else:
                        decoded_parts = []
            except:
                pass

        return text.strip() if text else None
    except Exception as e:
        return None


def get_contacts():
    """Build phone->name mapping"""
    contacts = {}
    if ADDRESSBOOK_DB:
        try:
            conn = sqlite3.connect(ADDRESSBOOK_DB)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT
                    COALESCE(ZFIRSTNAME, '') || ' ' || COALESCE(ZLASTNAME, ''),
                    ZFULLNUMBER
                FROM ZABCDRECORD
                LEFT JOIN ZABCDPHONENUMBER ON ZABCDRECORD.Z_PK = ZABCDPHONENUMBER.ZOWNER
                WHERE ZFULLNUMBER IS NOT NULL
            """)
            for name, phone in cursor.fetchall():
                if phone:
                    # Normalize phone number
                    normalized = re.sub(r'\D', '', phone)
                    if normalized.startswith('1') and len(normalized) > 10:
                        normalized = normalized[1:]
                    if len(normalized) >= 10:
                        contacts[normalized[-10:]] = name.strip()
            conn.close()
        except Exception as e:
            print(f"Warning: Could not read contacts: {e}")
    return contacts


def get_name(phone, contacts):
    """Get name from phone number"""
    if not phone:
        return "Unknown"
    normalized = re.sub(r'\D', '', phone)
    if normalized.startswith('1') and len(normalized) > 10:
        normalized = normalized[1:]
    if len(normalized) >= 10:
        return contacts.get(normalized[-10:], f"...{phone[-4:]}")
    return f"...{phone[-4:]}"


def main():
    conn = sqlite3.connect(IMESSAGE_DB)
    cursor = conn.cursor()

    contacts = get_contacts()

    # Get all messages from the group chat
    placeholders = ','.join(['?'] * len(CHAT_IDS))
    query = f"""
        SELECT
            m.ROWID,
            h.id as sender_phone,
            m.is_from_me,
            m.attributedBody,
            m.text,
            m.date/1000000000 + 978307200 as unix_ts,
            m.associated_message_type
        FROM message m
        JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
        JOIN chat c ON cmj.chat_id = c.ROWID
        LEFT JOIN handle h ON m.handle_id = h.ROWID
        WHERE c.chat_identifier IN ({placeholders})
          AND m.date/1000000000 >= ?
          AND m.date/1000000000 < ?
        ORDER BY m.date ASC
    """

    cursor.execute(query, CHAT_IDS + [START_2025, END_2025])

    messages = []
    message_counts = defaultdict(int)
    reaction_counts = defaultdict(lambda: defaultdict(int))
    hourly_counts = defaultdict(int)
    daily_counts = defaultdict(int)
    monthly_counts = defaultdict(int)
    date_counts = defaultdict(int)

    total_reactions = {'loved': 0, 'liked': 0, 'disliked': 0, 'laughed': 0, 'emphasized': 0, 'questioned': 0}

    for row in cursor.fetchall():
        rowid, sender_phone, is_from_me, attr_body, text_col, unix_ts, assoc_type = row

        # Handle reactions (associated_message_type 2000-2005)
        if assoc_type and assoc_type >= 2000 and assoc_type <= 2005:
            reaction_map = {2000: 'loved', 2001: 'liked', 2002: 'disliked', 2003: 'laughed', 2004: 'emphasized', 2005: 'questioned'}
            total_reactions[reaction_map.get(assoc_type, 'other')] = total_reactions.get(reaction_map.get(assoc_type), 0) + 1
            continue

        # Get text content
        text = text_col
        if not text and attr_body:
            text = extract_text_from_attributed_body(attr_body)

        if not text or len(text.strip()) < 2:
            continue

        # Determine sender
        if is_from_me:
            sender = "YOU"
            sender_display = "You"
        else:
            sender = sender_phone
            sender_display = get_name(sender_phone, contacts)

        dt = datetime.fromtimestamp(unix_ts)

        messages.append({
            'sender': sender,
            'sender_display': sender_display,
            'text': text.strip(),
            'timestamp': unix_ts,
            'datetime': dt.strftime('%Y-%m-%d %H:%M'),
            'date': dt.strftime('%Y-%m-%d'),
            'hour': dt.hour,
            'day_of_week': dt.strftime('%A'),
            'month': dt.strftime('%B')
        })

        # Count stats
        message_counts[sender_display] += 1
        hourly_counts[dt.hour] += 1
        daily_counts[dt.strftime('%A')] += 1
        monthly_counts[dt.strftime('%B')] += 1
        date_counts[dt.strftime('%Y-%m-%d')] += 1

    conn.close()

    # Find interesting messages
    interesting = []

    # Messages with lots of caps (excitement!)
    for m in messages:
        caps_ratio = sum(1 for c in m['text'] if c.isupper()) / max(len(m['text']), 1)
        if caps_ratio > 0.5 and len(m['text']) > 10:
            interesting.append({**m, 'category': 'CAPS_EXCITEMENT'})

    # Messages with question marks (debates!)
    for m in messages:
        if m['text'].count('?') >= 2:
            interesting.append({**m, 'category': 'QUESTIONER'})

    # Short punchy messages (reactions)
    for m in messages:
        if 3 <= len(m['text']) <= 20 and not m['text'].startswith('Loved'):
            interesting.append({**m, 'category': 'SHORT_REACTION'})

    # Messages with emojis
    emoji_pattern = re.compile("["
        u"\U0001F600-\U0001F64F"
        u"\U0001F300-\U0001F5FF"
        u"\U0001F680-\U0001F6FF"
        u"\U0001F1E0-\U0001F1FF"
        "]+", flags=re.UNICODE)

    for m in messages:
        if emoji_pattern.search(m['text']):
            interesting.append({**m, 'category': 'EMOJI_KING'})

    # Longest messages (essay writers)
    sorted_by_length = sorted(messages, key=lambda x: len(x['text']), reverse=True)[:5]
    for m in sorted_by_length:
        interesting.append({**m, 'category': 'ESSAY_WRITER'})

    # Get peak stats
    peak_hour = max(hourly_counts.items(), key=lambda x: x[1]) if hourly_counts else (0, 0)
    peak_day = max(daily_counts.items(), key=lambda x: x[1]) if daily_counts else ('Monday', 0)
    busiest_date = max(date_counts.items(), key=lambda x: x[1]) if date_counts else ('2025-01-01', 0)

    # Sort leaderboard
    leaderboard = sorted(message_counts.items(), key=lambda x: x[1], reverse=True)

    # Format hour nicely
    def format_hour(h):
        if h == 0: return "12 AM"
        elif h < 12: return f"{h} AM"
        elif h == 12: return "12 PM"
        else: return f"{h-12} PM"

    # Output results as JSON
    result = {
        'total_messages': len(messages),
        'total_reactions': sum(total_reactions.values()),
        'reaction_breakdown': total_reactions,
        'leaderboard': [{'name': name, 'count': count} for name, count in leaderboard[:10]],
        'peak_hour': format_hour(peak_hour[0]),
        'peak_hour_count': peak_hour[1],
        'peak_day': peak_day[0],
        'peak_day_count': peak_day[1],
        'busiest_date': busiest_date[0],
        'busiest_date_count': busiest_date[1],
        'first_message': messages[0] if messages else None,
        'last_message': messages[-1] if messages else None,
        'hourly_data': dict(hourly_counts),
        'daily_data': dict(daily_counts),
        'monthly_data': dict(monthly_counts),
        'sample_messages': messages[:100] if len(messages) > 100 else messages,
        'interesting_messages': interesting[:30]
    }

    print(json.dumps(result, indent=2, default=str))


if __name__ == "__main__":
    main()
