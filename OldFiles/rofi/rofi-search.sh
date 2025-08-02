
#!/usr/bin/env bash
#

# Defining our web browser.
DMBROWSER="google-chrome-stable"

# An array of search engines.  You can edit this list to add/remove
# search engines. The format must be: "engine_name - url".
# The url format must allow for the search keywords at the end of the url.
# For example: https://www.amazon.com/s?k=XXXX searches Amazon for 'XXXX'.
declare -a options=(
"1- google - https://www.google.com/search?q="
"2- duckduckgo - https://duckduckgo.com/?q="
"3- youtube - https://www.youtube.com/results?search_query="
"4- español - https://www.deepl.com/es/translator#es/en/"
"5- ingles - https://www.deepl.com/es/translator#en/es/"
"quit"
)

# Picking a search engine.
while [ -z "$engine" ]; do
enginelist=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i 20 -p '?') || exit
engineurl=$(echo "$enginelist" | awk '{print $NF}')
engine=$(echo "$enginelist" | awk '{print $1}')
done

# Searching the chosen engine.
while [ -z "$query" ]; do
query=$(rofi -dmenu -i 20 -p "Searching $engine:") || exit
done

# Display search results in web browser
$DMBROWSER "$engineurl""$query"
