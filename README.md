#Summary
Get the top k and bottom k skills of public linkedin profiles based on keywords.
The project uses google custom search engine to find public profiles matching keywords.
The public linkedin profile are then scrapped and skills are extracted from it.
In the end top k and bottom k skills across all these profiles are computed and stored in an output file.


#Pre-Requisites
* Requires ruby version >= 1.9.3
* Requires google-api-client gem 
     * Install: gem install google-api-client
* Requires nokogiri gem
     * Install: gem install nokogiri
   
   
#Config

* "SEARCH_EXTRA_KEYWORDS":[comma seperated keywords]// example "pub,in,profile"
* "SEARCH_URL":[google custom search url]
* "API_KEY":[google app api key]
* "SEARCH_ENGINE_ID":[google custom search engine id]
* "PROFILES_PER_KEYWORD": [NO. of profiles per keyword] //example "100"
* "FUZZYNESS":<fuzzy factor>// "1"-> To allow profiles with partial keyword matches 
                          // "0" -> To allow profiles with exact  keyword match                                         
* "TOP_SKILL_WINDOW": <Top Window Size>// example "10" (window size of the top skills)
* "BOTTOM_SKILL_WINDOW":<Bottom Window Size>// example "10" (window size of the bottom skills)


#USAGE 
ruby Linkedin_Profile_Scrapper.rb   [CONFIG_FILE]   [INPUT FILE LOCATION]   [OUTPUT FILE LOCATION]