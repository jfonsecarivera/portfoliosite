#!/usr/bin/env python3
"""Extract messages from Helen chat - v2 with better blob parsing"""

import sqlite3
import os
import re
from datetime import datetime

IMESSAGE_DB = os.path.expanduser("~/Library/Messages/chat.db")
CHAT_ID = "+14082188620"
START_2025 = 757382400
END_2025 = 788918400

def extract_text_from_blob(blob):
    """Extract text from NSAttributedString blob"""
    if not blob:
        return None

    try:
        # The text is after "NSString" marker (4E53537472696E67) then 019484012B then length byte
        hex_str = blob.hex()

        # Find NSString marker
        ns_string_marker = "4e53537472696e67"  # NSString in hex
        idx = hex_str.lower().find(ns_string_marker)

        if idx == -1:
            return None

        # Skip past marker and look for the text
        # Pattern is: NSString + 019484012B + length_byte + actual_text
        search_start = idx + len(ns_string_marker)
        remaining = hex_str[search_start:]

        # Find 019484012B pattern
        pattern_idx = remaining.lower().find("019484012b")
        if pattern_idx == -1:
            return None

        # Skip past 019484012B (10 chars)
        text_start = pattern_idx + 10

        # Next byte is length (in hex, so 2 chars)
        length_hex = remaining[text_start:text_start+2]
        try:
            text_length = int(length_hex, 16)
        except:
            return None

        # Extract the text hex and decode
        text_hex = remaining[text_start+2:text_start+2+text_length*2]

        try:
            text = bytes.fromhex(text_hex).decode('utf-8')
            return text
        except:
            return None

    except Exception as e:
        return None

conn = sqlite3.connect(IMESSAGE_DB)
cursor = conn.cursor()

# Get messages
cursor.execute("""
    SELECT
        m.is_from_me,
        m.attributedBody,
        m.text,
        m.date/1000000000 + 978307200 as unix_ts,
        m.associated_message_type
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier = ?
      AND m.date/1000000000 >= ?
      AND m.date/1000000000 < ?
    ORDER BY RANDOM()
    LIMIT 1000
""", (CHAT_ID, START_2025, END_2025))

messages = []
for row in cursor.fetchall():
    is_from_me, attr_body, text_col, unix_ts, assoc_type = row

    # Skip reactions
    if assoc_type and assoc_type >= 2000:
        continue

    text = text_col
    if not text and attr_body:
        text = extract_text_from_blob(attr_body)

    if not text or len(text.strip()) < 3:
        continue

    sender = "You" if is_from_me else "Helen"
    dt = datetime.fromtimestamp(unix_ts)

    messages.append({
        'sender': sender,
        'text': text.strip(),
        'date': dt.strftime('%Y-%m-%d'),
        'time': dt.strftime('%H:%M')
    })

conn.close()

# Find interesting messages
interesting = {
    'caps': [],
    'questions': [],
    'sweet': [],
    'short_funny': [],
    'excited': [],
}

for m in messages:
    text = m['text']

    # ALL CAPS
    if len(text) > 8:
        caps = sum(1 for c in text if c.isupper())
        letters = sum(1 for c in text if c.isalpha())
        if letters > 0 and caps / letters > 0.6:
            interesting['caps'].append(m)

    # Questions
    if text.count('?') >= 2 and len(text) < 80:
        interesting['questions'].append(m)

    # Sweet messages
    sweet_words = ['love you', 'miss you', 'i love', 'youre the', "you're the", 'so cute', 'my favorite', 'adore']
    if any(w in text.lower() for w in sweet_words):
        interesting['sweet'].append(m)

    # Short funny
    if 5 <= len(text) <= 40 and not any(x in text.lower() for x in ['ok', 'okay', 'yeah', 'yes', 'no', 'lol']):
        interesting['short_funny'].append(m)

    # Excited (!)
    if text.count('!') >= 2 and len(text) < 60:
        interesting['excited'].append(m)

print("=== SAMPLE MESSAGES ===")
for m in messages[:30]:
    print(f"{m['sender']}: {m['text'][:100]}")
print()

print("=== CAPS/EXCITED ===")
for m in interesting['caps'][:10]:
    print(f"{m['sender']}: {m['text'][:80]}")
print()

print("=== QUESTIONS ===")
for m in interesting['questions'][:10]:
    print(f"{m['sender']}: {m['text'][:80]}")
print()

print("=== SWEET ===")
for m in interesting['sweet'][:10]:
    print(f"{m['sender']}: {m['text'][:80]}")
print()

print("=== SHORT/PUNCHY ===")
for m in interesting['short_funny'][:15]:
    print(f"{m['sender']}: {m['text']}")
