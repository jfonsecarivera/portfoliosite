#!/usr/bin/env python3
"""Extract messages from Helen chat"""

import sqlite3
import os
import re
import json
from datetime import datetime

IMESSAGE_DB = os.path.expanduser("~/Library/Messages/chat.db")
CHAT_ID = "+14082188620"
START_2025 = 757382400
END_2025 = 788918400

def extract_text(blob):
    """Extract text from attributedBody blob"""
    if not blob:
        return None
    try:
        decoded = blob.decode('utf-8', errors='ignore')
        # Find sequences of normal text
        matches = re.findall(r'[\x20-\x7E]{5,}', decoded)
        for m in matches:
            if not any(x in m for x in ['NSString', 'NSDict', 'NSValue', 'NSNumber', 'class', 'streamtyped', 'bplist', 'NSMutable', 'kIM']):
                return m.strip()
        return None
    except:
        return None

conn = sqlite3.connect(IMESSAGE_DB)
cursor = conn.cursor()

# Get messages
cursor.execute("""
    SELECT
        m.ROWID,
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
    LIMIT 500
""", (CHAT_ID, START_2025, END_2025))

messages = []
for row in cursor.fetchall():
    rowid, is_from_me, attr_body, text_col, unix_ts, assoc_type = row

    # Skip reactions
    if assoc_type and assoc_type >= 2000:
        continue

    text = text_col
    if not text and attr_body:
        text = extract_text(attr_body)

    if not text or len(text.strip()) < 5:
        continue

    # Clean up
    text = text.strip()
    if text.startswith('+'):
        text = text[1:].strip()

    sender = "You" if is_from_me else "Helen"
    dt = datetime.fromtimestamp(unix_ts)

    messages.append({
        'sender': sender,
        'text': text,
        'date': dt.strftime('%Y-%m-%d'),
        'time': dt.strftime('%H:%M')
    })

conn.close()

# Find interesting messages
interesting = []

for m in messages:
    # ALL CAPS excitement
    if len(m['text']) > 10:
        caps = sum(1 for c in m['text'] if c.isupper())
        if caps > len(m['text']) * 0.5:
            interesting.append({**m, 'category': 'CAPS'})

    # Question marks (confusion/curiosity)
    if m['text'].count('?') >= 2:
        interesting.append({**m, 'category': 'QUESTIONS'})

    # Exclamation marks (excitement)
    if m['text'].count('!') >= 2:
        interesting.append({**m, 'category': 'EXCITED'})

    # Short punchy
    if 5 <= len(m['text']) <= 25:
        interesting.append({**m, 'category': 'SHORT'})

    # Love/affection keywords
    if any(word in m['text'].lower() for word in ['love', 'miss', 'cute', 'babe', 'baby']):
        interesting.append({**m, 'category': 'SWEET'})

# Print results
print("=== SAMPLE MESSAGES ===")
for m in messages[:50]:
    print(f"{m['sender']}: {m['text'][:80]}")
    print()

print("\n=== INTERESTING MESSAGES ===")
for m in interesting[:30]:
    print(f"[{m['category']}] {m['sender']}: {m['text'][:80]}")
    print()
