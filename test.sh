#!/bin/bash

# iMessage 2025 Contact Analyzer
# This script finds everyone you messaged in 2025 on iMessage,
# matches them with contact names, and shows message counts.
# Separates direct messages from group chat participants.

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           iMessage 2025 Contact Analysis${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Path to iMessage database
IMESSAGE_DB="$HOME/Library/Messages/chat.db"

# Check if database exists
if [ ! -f "$IMESSAGE_DB" ]; then
    echo -e "${YELLOW}Error: iMessage database not found at $IMESSAGE_DB${NC}"
    echo "Make sure you're running this on macOS with iMessage set up."
    exit 1
fi

# Check for Full Disk Access
if ! sqlite3 "$IMESSAGE_DB" "SELECT 1 LIMIT 1" 2>/dev/null; then
    echo -e "${YELLOW}Error: Cannot access iMessage database.${NC}"
    echo ""
    echo "Please grant Full Disk Access to your terminal app:"
    echo "1. Open System Settings > Privacy & Security > Full Disk Access"
    echo "2. Click the + button and add your terminal app (Warp, Terminal, iTerm, etc.)"
    echo "3. Restart your terminal and run this script again"
    exit 1
fi

# Create temporary files
CONTACT_CACHE=$(mktemp)
SENT_CACHE=$(mktemp)
DIRECT_IDS=$(mktemp)
trap "rm -f $CONTACT_CACHE $SENT_CACHE $DIRECT_IDS" EXIT

# Try to build a contact lookup table from the AddressBook database
echo -e "${GREEN}Building contact lookup table...${NC}"

# Find the AddressBook database(s)
ADDRESSBOOK_DBS=$(find "$HOME/Library/Application Support/AddressBook" -name "AddressBook-v22.abcddb" 2>/dev/null)

if [ -n "$ADDRESSBOOK_DBS" ]; then
    while IFS= read -r db; do
        sqlite3 "$db" "
            SELECT 
                COALESCE(ZFIRSTNAME, '') || ' ' || COALESCE(ZLASTNAME, '') as name,
                ZFULLNUMBER as identifier
            FROM ZABCDRECORD 
            LEFT JOIN ZABCDPHONENUMBER ON ZABCDRECORD.Z_PK = ZABCDPHONENUMBER.ZOWNER
            WHERE ZFULLNUMBER IS NOT NULL
            UNION
            SELECT 
                COALESCE(ZFIRSTNAME, '') || ' ' || COALESCE(ZLASTNAME, '') as name,
                ZADDRESS as identifier
            FROM ZABCDRECORD 
            LEFT JOIN ZABCDEMAILADDRESS ON ZABCDRECORD.Z_PK = ZABCDEMAILADDRESS.ZOWNER
            WHERE ZADDRESS IS NOT NULL;
        " 2>/dev/null >> "$CONTACT_CACHE"
    done <<< "$ADDRESSBOOK_DBS"
fi

# Function to normalize phone numbers for matching
normalize_phone() {
    echo "$1" | tr -cd '0-9' | sed 's/^1//'
}

# Function to lookup contact name
lookup_contact() {
    local identifier="$1"
    local normalized=$(normalize_phone "$identifier")
    
    local match=$(grep -i "|$identifier$" "$CONTACT_CACHE" 2>/dev/null | head -1 | cut -d'|' -f1)
    
    if [ -z "$match" ] || [ "$match" = " " ]; then
        if [ ${#normalized} -ge 10 ]; then
            match=$(grep -E "\|.*${normalized: -10}$" "$CONTACT_CACHE" 2>/dev/null | head -1 | cut -d'|' -f1)
        fi
    fi
    
    match=$(echo "$match" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -n "$match" ] && [ "$match" != " " ]; then
        echo "$match"
    else
        echo ""
    fi
}

# Function to lookup sent count
lookup_sent() {
    local identifier="$1"
    local result=$(grep -F "$identifier|" "$SENT_CACHE" 2>/dev/null | head -1 | cut -d'|' -f2)
    echo "${result:-0}"
}

echo -e "${GREEN}Querying iMessage database for 2025 messages...${NC}"
echo ""

# Apple's Core Data timestamp: seconds since 2001-01-01
START_2025=757382400
END_2025=788918400

# ============================================================
# DIRECT MESSAGES (1-on-1 conversations)
# ============================================================
echo -e "${GREEN}Fetching direct messages...${NC}"

DIRECT_RESULTS=$(sqlite3 "$IMESSAGE_DB" "
    SELECT 
        h.id as contact_id,
        COUNT(m.ROWID) as message_count
    FROM handle h
    JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
    JOIN chat c ON chj.chat_id = c.ROWID
    JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
    JOIN message m ON cmj.message_id = m.ROWID
    WHERE m.date/1000000000 >= $START_2025 
      AND m.date/1000000000 < $END_2025
      AND c.chat_identifier NOT LIKE 'chat%'
      AND LENGTH(REPLACE(REPLACE(REPLACE(h.id, '+', ''), '-', ''), ' ', '')) > 6
    GROUP BY h.id
    HAVING message_count > 5
    ORDER BY message_count DESC;
")

# Get sent counts for direct messages
SENT_DIRECT=$(sqlite3 "$IMESSAGE_DB" "
    SELECT 
        h.id as contact_id,
        COUNT(m.ROWID) as sent_count
    FROM handle h
    JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
    JOIN chat c ON chj.chat_id = c.ROWID
    JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
    JOIN message m ON cmj.message_id = m.ROWID
    WHERE m.date/1000000000 >= $START_2025 
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 1
      AND c.chat_identifier NOT LIKE 'chat%'
    GROUP BY h.id;
")
echo "$SENT_DIRECT" > "$SENT_CACHE"

# Save direct contact IDs for exclusion from group list
echo "$DIRECT_RESULTS" | cut -d'|' -f1 > "$DIRECT_IDS"

# Print direct messages header
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  DIRECT MESSAGES (1-on-1 conversations)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf "%-35s %-25s %10s %10s\n" "CONTACT NAME" "IDENTIFIER" "TOTAL" "SENT"
echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

direct_contacts=0
direct_messages=0

while IFS='|' read -r contact_id message_count; do
    if [ -n "$contact_id" ]; then
        contact_name=$(lookup_contact "$contact_id")
        sent=$(lookup_sent "$contact_id")
        
        display_id="$contact_id"
        if [ ${#display_id} -gt 24 ]; then
            display_id="${display_id:0:21}..."
        fi
        
        display_name="${contact_name:-[Unknown]}"
        if [ ${#display_name} -gt 34 ]; then
            display_name="${display_name:0:31}..."
        fi
        
        printf "%-35s %-25s %10s %10s\n" "$display_name" "$display_id" "$message_count" "$sent"
        
        ((direct_contacts++))
        ((direct_messages+=message_count))
    fi
done <<< "$DIRECT_RESULTS"

echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}Direct contacts: $direct_contacts | Total messages: $direct_messages${NC}"

# ============================================================
# GROUP CHAT PARTICIPANTS (people you only see in groups)
# ============================================================
echo ""
echo -e "${GREEN}Fetching group chat participants...${NC}"

GROUP_RESULTS=$(sqlite3 "$IMESSAGE_DB" "
    SELECT 
        h.id as contact_id,
        COUNT(m.ROWID) as message_count
    FROM handle h
    JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
    JOIN chat c ON chj.chat_id = c.ROWID
    JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
    JOIN message m ON cmj.message_id = m.ROWID
    WHERE m.date/1000000000 >= $START_2025 
      AND m.date/1000000000 < $END_2025
      AND c.chat_identifier LIKE 'chat%'
      AND LENGTH(REPLACE(REPLACE(REPLACE(h.id, '+', ''), '-', ''), ' ', '')) > 6
    GROUP BY h.id
    HAVING message_count > 5
    ORDER BY message_count DESC;
")

# Get sent counts for group messages
SENT_GROUP=$(sqlite3 "$IMESSAGE_DB" "
    SELECT 
        h.id as contact_id,
        COUNT(m.ROWID) as sent_count
    FROM handle h
    JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
    JOIN chat c ON chj.chat_id = c.ROWID
    JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
    JOIN message m ON cmj.message_id = m.ROWID
    WHERE m.date/1000000000 >= $START_2025 
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 1
      AND c.chat_identifier LIKE 'chat%'
    GROUP BY h.id;
")
echo "$SENT_GROUP" > "$SENT_CACHE"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  GROUP CHAT PARTICIPANTS (only in group chats)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf "%-35s %-25s %10s %10s\n" "CONTACT NAME" "IDENTIFIER" "TOTAL" "SENT"
echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

group_contacts=0
group_messages=0

while IFS='|' read -r contact_id message_count; do
    if [ -n "$contact_id" ]; then
        # Skip if this person is already in direct messages
        if grep -qxF "$contact_id" "$DIRECT_IDS" 2>/dev/null; then
            continue
        fi
        
        contact_name=$(lookup_contact "$contact_id")
        sent=$(lookup_sent "$contact_id")
        
        display_id="$contact_id"
        if [ ${#display_id} -gt 24 ]; then
            display_id="${display_id:0:21}..."
        fi
        
        display_name="${contact_name:-[Unknown]}"
        if [ ${#display_name} -gt 34 ]; then
            display_name="${display_name:0:31}..."
        fi
        
        printf "%-35s %-25s %10s %10s\n" "$display_name" "$display_id" "$message_count" "$sent"
        
        ((group_contacts++))
        ((group_messages+=message_count))
    fi
done <<< "$GROUP_RESULTS"

echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}Group-only contacts: $group_contacts | Total messages: $group_messages${NC}"

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo "  Direct message contacts:    $direct_contacts"
echo "  Group-only contacts:        $group_contacts"
echo "  Total unique contacts:      $((direct_contacts + group_contacts))"
echo ""

# Export option
echo -e "${YELLOW}Export to CSV? (y/n)${NC}"
read -r export_choice

if [ "$export_choice" = "y" ] || [ "$export_choice" = "Y" ]; then
    OUTPUT_FILE="$HOME/Desktop/imessage_2025_contacts_$(date +%Y%m%d_%H%M%S).csv"
    
    echo "Type,Contact Name,Identifier,Total Messages,Messages Sent" > "$OUTPUT_FILE"
    
    # Export direct messages
    echo "$SENT_DIRECT" > "$SENT_CACHE"
    while IFS='|' read -r contact_id message_count; do
        if [ -n "$contact_id" ]; then
            contact_name=$(lookup_contact "$contact_id")
            sent=$(lookup_sent "$contact_id")
            contact_name=$(echo "$contact_name" | sed 's/"/""/g')
            contact_id_escaped=$(echo "$contact_id" | sed 's/"/""/g')
            echo "Direct,\"${contact_name:-Unknown}\",\"$contact_id_escaped\",$message_count,$sent" >> "$OUTPUT_FILE"
        fi
    done <<< "$DIRECT_RESULTS"
    
    # Export group-only contacts
    echo "$SENT_GROUP" > "$SENT_CACHE"
    while IFS='|' read -r contact_id message_count; do
        if [ -n "$contact_id" ]; then
            if grep -qxF "$contact_id" "$DIRECT_IDS" 2>/dev/null; then
                continue
            fi
            contact_name=$(lookup_contact "$contact_id")
            sent=$(lookup_sent "$contact_id")
            contact_name=$(echo "$contact_name" | sed 's/"/""/g')
            contact_id_escaped=$(echo "$contact_id" | sed 's/"/""/g')
            echo "Group,\"${contact_name:-Unknown}\",\"$contact_id_escaped\",$message_count,$sent" >> "$OUTPUT_FILE"
        fi
    done <<< "$GROUP_RESULTS"
    
    echo -e "${GREEN}Exported to: $OUTPUT_FILE${NC}"
fi

echo ""
echo -e "${BLUE}Done!${NC}"