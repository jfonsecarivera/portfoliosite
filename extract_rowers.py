#!/usr/bin/env python3
"""Extract messages from Austin Rowers chat"""

import sqlite3
import os
import re
from datetime import datetime

IMESSAGE_DB = os.path.expanduser("~/Library/Messages/chat.db")
CHAT_ID = "chat24782973880428938"
START_2025 = 757382400
END_2025 = 788918400

# Contact mapping
CONTACTS = {
    '6415902303': 'Ethan',
    '9152404859': 'Andy',
    '7605858660': 'Jake',
    '2014507090': 'Mystery 7090',
    '2817556189': 'Drew',
    '2105017604': 'Savannah',
    '2404472571': 'Will',
    '3125136750': 'Dillon',
    '7602200749': 'Dallin',
    '9204616252': 'Bryn',
    '4082188620': 'Helen',
    '5127435839': 'Liz',
    '5129229166': 'Durham',
    '9739860986': 'Nina',
    '6094018119': 'Mystery 8119',
    '8589225573': 'Zac',
    '5514277990': 'Mystery 7990',
    '3373095448': 'Mystery 5448',
}

def get_name(phone):
    if not phone:
        return 'Unknown'
    normalized = re.sub(r'\D', '', phone)
    if normalized.startswith('1') and len(normalized) > 10:
        normalized = normalized[1:]
    return CONTACTS.get(normalized[-10:], f'...{phone[-4:]}')

def extract_text_from_blob(blob):
    if not blob:
        return None
    try:
        hex_str = blob.hex()
        ns_string_marker = '4e53537472696e67'
        idx = hex_str.lower().find(ns_string_marker)
        if idx == -1:
            return None
        remaining = hex_str[idx + len(ns_string_marker):]
        pattern_idx = remaining.lower().find('019484012b')
        if pattern_idx == -1:
            return None
        text_start = pattern_idx + 10
        length_hex = remaining[text_start:text_start+2]
        text_length = int(length_hex, 16)
        text_hex = remaining[text_start+2:text_start+2+text_length*2]
        return bytes.fromhex(text_hex).decode('utf-8')
    except:
        return None

conn = sqlite3.connect(IMESSAGE_DB)
cursor = conn.cursor()

cursor.execute("""
    SELECT
        m.is_from_me,
        h.id,
        m.attributedBody,
        m.text,
        m.date/1000000000 + 978307200 as unix_ts
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    LEFT JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier = ?
      AND m.date/1000000000 >= ? AND m.date/1000000000 < ?
      AND m.associated_message_type IS NULL
    ORDER BY RANDOM() LIMIT 800
""", (CHAT_ID, START_2025, END_2025))

messages = []
for row in cursor.fetchall():
    is_from_me, phone, attr_body, text_col, unix_ts = row

    text = text_col or extract_text_from_blob(attr_body)
    if not text or len(text.strip()) < 3:
        continue

    sender = 'You' if is_from_me else get_name(phone)
    dt = datetime.fromtimestamp(unix_ts)

    messages.append({
        'sender': sender,
        'text': text.strip(),
        'date': dt.strftime('%Y-%m-%d'),
    })

conn.close()

# Find interesting messages
caps_msgs = []
questions = []
short_punchy = []
excited = []

for m in messages:
    text = m['text']

    # CAPS
    letters = sum(1 for c in text if c.isalpha())
    caps = sum(1 for c in text if c.isupper())
    if letters > 5 and caps/letters > 0.6 and len(text) > 8:
        caps_msgs.append(m)

    # Questions
    if text.count('?') >= 2 and len(text) < 100:
        questions.append(m)

    # Short punchy (good for quotes)
    if 5 <= len(text) <= 50:
        short_punchy.append(m)

    # Excited
    if text.count('!') >= 2 and len(text) < 80:
        excited.append(m)

print("=== SAMPLE MESSAGES ===")
for m in messages[:40]:
    print(f"{m['sender']}: {m['text'][:80]}")
print()

print("=== CAPS/YELLING ===")
for m in caps_msgs[:10]:
    print(f"{m['sender']}: {m['text'][:80]}")
print()

print("=== QUESTIONS ===")
for m in questions[:10]:
    print(f"{m['sender']}: {m['text'][:80]}")
print()

print("=== EXCITED ===")
for m in excited[:15]:
    print(f"{m['sender']}: {m['text'][:80]}")
