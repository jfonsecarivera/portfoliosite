#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║            🎬 9PM MOVIE CLUB WRAPPED 2025 🍿                               ║
# ║                    Your Year in Texts                                      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
BG_MAGENTA='\033[45m'
BG_BLUE='\033[44m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'

# Database path
IMESSAGE_DB="$HOME/Library/Messages/chat.db"
ADDRESSBOOK_DB=$(find "$HOME/Library/Application Support/AddressBook" -name "AddressBook-v22.abcddb" 2>/dev/null | head -1)

# The group chat identifiers (multiple entries for same group)
CHAT_IDS="('chat53137152716289611', 'chat391035900966244623')"

# Apple timestamps for 2025
START_2025=757382400
END_2025=788918400

# Create temp file for contact cache
CONTACT_CACHE=$(mktemp)
trap "rm -f $CONTACT_CACHE" EXIT

# Build contact lookup
if [ -n "$ADDRESSBOOK_DB" ]; then
    sqlite3 "$ADDRESSBOOK_DB" "
        SELECT
            COALESCE(ZFIRSTNAME, '') || '|' || REPLACE(REPLACE(REPLACE(REPLACE(ZFULLNUMBER, ' ', ''), '-', ''), '(', ''), ')', '')
        FROM ZABCDRECORD
        LEFT JOIN ZABCDPHONENUMBER ON ZABCDRECORD.Z_PK = ZABCDPHONENUMBER.ZOWNER
        WHERE ZFULLNUMBER IS NOT NULL AND ZFIRSTNAME IS NOT NULL;
    " 2>/dev/null > "$CONTACT_CACHE"
fi

# Function to get first name from phone number
get_name() {
    local phone="$1"
    # Remove all non-digits and strip leading 1
    local normalized=$(echo "$phone" | tr -cd '0-9' | sed 's/^1//')
    local match=""

    # Try to match last 10 digits
    if [ ${#normalized} -ge 10 ]; then
        local last10="${normalized: -10}"
        match=$(grep "${last10}" "$CONTACT_CACHE" 2>/dev/null | head -1 | cut -d'|' -f1)
    fi

    # Clean up the match
    match=$(echo "$match" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -n "$match" ] && [ "$match" != " " ] && [ "$match" != "" ]; then
        echo "$match"
    else
        # Return last 4 digits if no name found
        echo "(...${phone: -4})"
    fi
}

clear

# Animated intro
sleep 0.3
echo ""
echo -e "${DIM}Loading your 2025...${NC}"
sleep 0.5
clear

# Title card
echo ""
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}   ${BOLD}${WHITE}🎬  9PM MOVIE CLUB WRAPPED 2025  🍿${NC}                        ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 1: Total Messages
# ═══════════════════════════════════════════════════════════════════════════

TOTAL_MESSAGES=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(m.ROWID)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025;
")

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${DIM}This year, your group chat sent...${NC}"
echo ""
sleep 0.5
echo -e "                    ${BOLD}${WHITE}${BG_MAGENTA}  $TOTAL_MESSAGES MESSAGES  ${NC}"
echo ""
echo -e "   ${DIM}That's a LOT of opinions about movies.${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 2: Most Active Member (MVP)
# ═══════════════════════════════════════════════════════════════════════════

MVP_DATA=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        h.id,
        COUNT(m.ROWID) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 0
    GROUP BY h.id
    ORDER BY cnt DESC
    LIMIT 1;
")

MVP_PHONE=$(echo "$MVP_DATA" | cut -d'|' -f1)
MVP_COUNT=$(echo "$MVP_DATA" | cut -d'|' -f2)
MVP_NAME=$(get_name "$MVP_PHONE")

YOUR_COUNT=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(m.ROWID)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 1;
")

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${YELLOW}🏆 THE YAPPER AWARD 🏆${NC}"
echo ""
sleep 0.5
echo -e "   ${DIM}Most messages sent goes to...${NC}"
echo ""

if [ "$YOUR_COUNT" -gt "${MVP_COUNT:-0}" ]; then
    echo -e "                    ${BOLD}${WHITE}${BG_YELLOW}  YOU!  ${NC}"
    echo -e "                    ${BOLD}$YOUR_COUNT messages${NC}"
    echo ""
    echo -e "   ${DIM}You really had a lot to say this year.${NC}"
else
    echo -e "                    ${BOLD}${WHITE}${BG_YELLOW}  $MVP_NAME  ${NC}"
    echo -e "                    ${BOLD}$MVP_COUNT messages${NC}"
    echo ""
    echo -e "   ${DIM}You sent $YOUR_COUNT messages (respectable).${NC}"
fi
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 3: Full Leaderboard
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${MAGENTA}📊 THE OFFICIAL RANKINGS 📊${NC}"
echo ""
sleep 0.5

# Get all members' message counts
LEADERBOARD=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        h.id,
        COUNT(m.ROWID) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 0
    GROUP BY h.id
    ORDER BY cnt DESC;
")

# Create combined leaderboard with you included
rank=1
printed_you=0

# First, collect all entries and sort
{
    echo "YOU|$YOUR_COUNT"
    echo "$LEADERBOARD"
} | sort -t'|' -k2 -nr | head -10 | while IFS='|' read -r phone count; do
    if [ "$phone" = "YOU" ]; then
        name="${BOLD}${GREEN}YOU${NC}"
    else
        name=$(get_name "$phone")
    fi

    case $rank in
        1) medal="🥇" ;;
        2) medal="🥈" ;;
        3) medal="🥉" ;;
        *) medal="  " ;;
    esac

    # Create a bar chart
    bar_length=$((count / (TOTAL_MESSAGES / 30 + 1)))
    bar=$(printf '█%.0s' $(seq 1 $bar_length))

    printf "   %s %-20s %s ${DIM}%s${NC}\n" "$medal" "$name" "$count" "$bar"
    ((rank++))
done

echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 4: Peak Hours
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${BLUE}🕐 PEAK TEXTING HOURS 🕐${NC}"
echo ""
sleep 0.5

HOURLY=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        CAST(strftime('%H', datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime')) AS INTEGER) as hour,
        COUNT(*) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
    GROUP BY hour
    ORDER BY cnt DESC;
")

PEAK_HOUR=$(echo "$HOURLY" | head -1 | cut -d'|' -f1)
PEAK_COUNT=$(echo "$HOURLY" | head -1 | cut -d'|' -f2)

# Format the hour nicely
if [ "$PEAK_HOUR" -eq 0 ]; then
    PEAK_FORMATTED="12 AM"
elif [ "$PEAK_HOUR" -lt 12 ]; then
    PEAK_FORMATTED="${PEAK_HOUR} AM"
elif [ "$PEAK_HOUR" -eq 12 ]; then
    PEAK_FORMATTED="12 PM"
else
    PEAK_FORMATTED="$((PEAK_HOUR - 12)) PM"
fi

echo -e "   ${DIM}Your group chat was most active at...${NC}"
echo ""
echo -e "                    ${BOLD}${WHITE}${BG_BLUE}  $PEAK_FORMATTED  ${NC}"
echo -e "                    ${DIM}($PEAK_COUNT messages)${NC}"
echo ""

# Check if 9pm is actually peak
if [ "$PEAK_HOUR" -eq 21 ]; then
    echo -e "   ${GREEN}Name checks out! 9PM really is your time.${NC}"
elif [ "$PEAK_HOUR" -ge 21 ] || [ "$PEAK_HOUR" -le 2 ]; then
    echo -e "   ${YELLOW}Night owls confirmed. 🦉${NC}"
else
    echo -e "   ${DIM}Should we rename it to \"${PEAK_FORMATTED} movie club\"?${NC}"
fi
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 5: Day of Week
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${GREEN}📅 BUSIEST DAY OF THE WEEK 📅${NC}"
echo ""
sleep 0.5

DAILY=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        CAST(strftime('%w', datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime')) AS INTEGER) as dow,
        COUNT(*) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
    GROUP BY dow
    ORDER BY dow;
")

DAYS=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")
MAX_DAY=0
MAX_COUNT=0

echo "$DAILY" | while IFS='|' read -r dow count; do
    day_name="${DAYS[$dow]}"
    bar_len=$((count / 20))
    bar=$(printf '▓%.0s' $(seq 1 $bar_len))
    printf "   %-11s %s ${DIM}%s${NC}\n" "$day_name" "$count" "$bar"

    if [ "$count" -gt "$MAX_COUNT" ]; then
        MAX_COUNT=$count
        MAX_DAY=$dow
    fi
done

BUSIEST_DAY_DATA=$(echo "$DAILY" | sort -t'|' -k2 -nr | head -1)
BUSIEST_DOW=$(echo "$BUSIEST_DAY_DATA" | cut -d'|' -f1)
BUSIEST_NAME="${DAYS[$BUSIEST_DOW]}"

echo ""
echo -e "   ${DIM}$BUSIEST_NAME hits different for movie discussions.${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 6: Late Night Texters
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${MAGENTA}🌙 THE INSOMNIAC AWARD 🌙${NC}"
echo -e "   ${DIM}(Most messages sent between 1-5 AM)${NC}"
echo ""
sleep 0.5

NIGHT_OWL=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        h.id,
        COUNT(*) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 0
      AND CAST(strftime('%H', datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime')) AS INTEGER) BETWEEN 1 AND 5
    GROUP BY h.id
    ORDER BY cnt DESC
    LIMIT 1;
")

YOUR_LATE=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.is_from_me = 1
      AND CAST(strftime('%H', datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime')) AS INTEGER) BETWEEN 1 AND 5;
")

NIGHT_PHONE=$(echo "$NIGHT_OWL" | cut -d'|' -f1)
NIGHT_COUNT=$(echo "$NIGHT_OWL" | cut -d'|' -f2)
NIGHT_NAME=$(get_name "$NIGHT_PHONE")

if [ "${YOUR_LATE:-0}" -gt "${NIGHT_COUNT:-0}" ]; then
    echo -e "                    ${BOLD}${WHITE}${BG_MAGENTA}  YOU  ${NC}"
    echo -e "                    ${DIM}$YOUR_LATE late night texts${NC}"
    echo ""
    echo -e "   ${DIM}Go to sleep. The movies will still be there tomorrow.${NC}"
else
    echo -e "                    ${BOLD}${WHITE}${BG_MAGENTA}  $NIGHT_NAME  ${NC}"
    echo -e "                    ${DIM}${NIGHT_COUNT:-0} late night texts${NC}"
    echo ""
    echo -e "   ${DIM}Someone needs to check on them.${NC}"
fi
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 7: Longest Message
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${YELLOW}📝 THE ESSAY WRITER AWARD 📝${NC}"
echo -e "   ${DIM}(Longest single message)${NC}"
echo ""
sleep 0.5

LONGEST=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        h.id,
        LENGTH(m.text) as len,
        m.is_from_me,
        SUBSTR(m.text, 1, 80)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    LEFT JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.text IS NOT NULL
    ORDER BY len DESC
    LIMIT 1;
")

LONG_PHONE=$(echo "$LONGEST" | cut -d'|' -f1)
LONG_LEN=$(echo "$LONGEST" | cut -d'|' -f2)
IS_FROM_ME=$(echo "$LONGEST" | cut -d'|' -f3)
LONG_PREVIEW=$(echo "$LONGEST" | cut -d'|' -f4)

if [ "$IS_FROM_ME" = "1" ]; then
    echo -e "                    ${BOLD}${WHITE}${BG_YELLOW}  YOU  ${NC}"
else
    LONG_NAME=$(get_name "$LONG_PHONE")
    echo -e "                    ${BOLD}${WHITE}${BG_YELLOW}  $LONG_NAME  ${NC}"
fi
echo -e "                    ${DIM}${LONG_LEN:-0} characters${NC}"
echo ""
echo -e "   ${DIM}\"${LONG_PREVIEW}...\"${NC}"
echo ""
echo -e "   ${DIM}Sir, this is a group chat, not a film review.${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 8: Reaction Stats
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${RED}❤️ REACTION STATS ❤️${NC}"
echo ""
sleep 0.5

# Count different reaction types
LOVED=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.associated_message_type = 2000;
")

LIKED=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.associated_message_type = 2001;
")

DISLIKED=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.associated_message_type = 2002;
")

LAUGHED=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.associated_message_type = 2003;
")

EMPHASIZED=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.associated_message_type = 2004;
")

QUESTIONED=$(sqlite3 "$IMESSAGE_DB" "
    SELECT COUNT(*)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.associated_message_type = 2005;
")

echo -e "   ❤️  Loved:      ${BOLD}$LOVED${NC}"
echo -e "   👍 Liked:      ${BOLD}$LIKED${NC}"
echo -e "   👎 Disliked:   ${BOLD}$DISLIKED${NC}"
echo -e "   😂 Ha-ha'd:    ${BOLD}$LAUGHED${NC}"
echo -e "   ‼️  Emphasized: ${BOLD}$EMPHASIZED${NC}"
echo -e "   ❓ Questioned: ${BOLD}$QUESTIONED${NC}"
echo ""
TOTAL_REACTIONS=$((LOVED + LIKED + DISLIKED + LAUGHED + EMPHASIZED + QUESTIONED))
echo -e "   ${DIM}Total reactions: $TOTAL_REACTIONS${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 9: First & Last Message
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${GREEN}📅 THE BOOKENDS OF 2025 📅${NC}"
echo ""
sleep 0.5

FIRST_MSG=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        h.id,
        m.is_from_me,
        datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime'),
        SUBSTR(m.text, 1, 50)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    LEFT JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.text IS NOT NULL
    ORDER BY m.date ASC
    LIMIT 1;
")

LAST_MSG=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        h.id,
        m.is_from_me,
        datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime'),
        SUBSTR(m.text, 1, 50)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    LEFT JOIN handle h ON m.handle_id = h.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
      AND m.text IS NOT NULL
    ORDER BY m.date DESC
    LIMIT 1;
")

FIRST_PHONE=$(echo "$FIRST_MSG" | cut -d'|' -f1)
FIRST_IS_ME=$(echo "$FIRST_MSG" | cut -d'|' -f2)
FIRST_DATE=$(echo "$FIRST_MSG" | cut -d'|' -f3)
FIRST_TEXT=$(echo "$FIRST_MSG" | cut -d'|' -f4)

LAST_PHONE=$(echo "$LAST_MSG" | cut -d'|' -f1)
LAST_IS_ME=$(echo "$LAST_MSG" | cut -d'|' -f2)
LAST_DATE=$(echo "$LAST_MSG" | cut -d'|' -f3)
LAST_TEXT=$(echo "$LAST_MSG" | cut -d'|' -f4)

echo -e "   ${BOLD}First message of 2025:${NC}"
if [ "$FIRST_IS_ME" = "1" ]; then
    echo -e "   ${GREEN}YOU${NC} on ${DIM}$FIRST_DATE${NC}"
else
    FIRST_NAME=$(get_name "$FIRST_PHONE")
    echo -e "   ${CYAN}$FIRST_NAME${NC} on ${DIM}$FIRST_DATE${NC}"
fi
echo -e "   ${DIM}\"$FIRST_TEXT...\"${NC}"
echo ""

echo -e "   ${BOLD}Most recent message:${NC}"
if [ "$LAST_IS_ME" = "1" ]; then
    echo -e "   ${GREEN}YOU${NC} on ${DIM}$LAST_DATE${NC}"
else
    LAST_NAME=$(get_name "$LAST_PHONE")
    echo -e "   ${CYAN}$LAST_NAME${NC} on ${DIM}$LAST_DATE${NC}"
fi
echo -e "   ${DIM}\"$LAST_TEXT...\"${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 10: Busiest Day
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${YELLOW}🔥 THE MOST LIT DAY OF 2025 🔥${NC}"
echo ""
sleep 0.5

BUSIEST=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        date(m.date/1000000000 + 978307200, 'unixepoch', 'localtime') as day,
        COUNT(*) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
    GROUP BY day
    ORDER BY cnt DESC
    LIMIT 1;
")

BUSIEST_DATE=$(echo "$BUSIEST" | cut -d'|' -f1)
BUSIEST_COUNT=$(echo "$BUSIEST" | cut -d'|' -f2)

echo -e "   ${DIM}Your wildest day was...${NC}"
echo ""
echo -e "                    ${BOLD}${WHITE}${BG_RED}  $BUSIEST_DATE  ${NC}"
echo -e "                    ${BOLD}$BUSIEST_COUNT messages${NC}"
echo ""
echo -e "   ${DIM}What movie caused THAT much drama?${NC}"
echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# STAT 11: Messages by Month
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${BLUE}📈 YOUR YEAR IN MOTION 📈${NC}"
echo ""
sleep 0.5

MONTHS=("" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")

MONTHLY=$(sqlite3 "$IMESSAGE_DB" "
    SELECT
        CAST(strftime('%m', datetime(m.date/1000000000 + 978307200, 'unixepoch', 'localtime')) AS INTEGER) as month,
        COUNT(*) as cnt
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE c.chat_identifier IN $CHAT_IDS
      AND m.date/1000000000 >= $START_2025
      AND m.date/1000000000 < $END_2025
    GROUP BY month
    ORDER BY month;
")

echo "$MONTHLY" | while IFS='|' read -r month count; do
    if [ -n "$month" ]; then
        month_name="${MONTHS[$month]}"
        bar_len=$((count / 15))
        bar=$(printf '▓%.0s' $(seq 1 $bar_len 2>/dev/null) 2>/dev/null)
        printf "   %-4s %4s %s\n" "$month_name" "$count" "$bar"
    fi
done

echo ""
sleep 1

# ═══════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}   ${BOLD}${WHITE}🎬  THAT'S A WRAP ON 2025!  🍿${NC}                             ${MAGENTA}║${NC}"
echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "   ${DIM}9pm Movie Club Stats:${NC}"
echo -e "   • ${BOLD}$TOTAL_MESSAGES${NC} total messages"
echo -e "   • ${BOLD}$TOTAL_REACTIONS${NC} reactions given"
echo -e "   • Peak hour: ${BOLD}$PEAK_FORMATTED${NC}"
echo -e "   • Busiest day: ${BOLD}$BUSIEST_DATE${NC}"
echo ""
echo -e "   ${DIM}Here's to more movie nights in 2026! 🎥${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
