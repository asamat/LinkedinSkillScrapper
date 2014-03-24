require 'rubygems'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'openssl'
require 'google/api_client'
require 'open-uri'
require 'nokogiri'

##<USAGE> : ruby Linkedin_Profile_Scrapper.rb <CONFIG_FILE> <INPUT FILE LOCATION> <OUTPUT FILE LOCATION>
class LinkedinSearch

  @@CONFIG_FILE=ARGV[0].nil? ? "config.json" : ARGV[0]
  @@INPUT_FILE=ARGV[1]
  @@OUTPUT_FILE=ARGV[2].nil? ? "Search_Output.txt" : ARGV[2]  
  @@USER_SKILLS={}
  @@PROFILES_DONE={}


  #inititalise
  def  self.init_config
    if !File.file?(@@CONFIG_FILE)
      puts "Please give a valid config File"
      exit 1
    end

    if !File.file?(@@INPUT_FILE)
      puts "Please give a valid input File"
      exit 1
    end
    cfg=JSON.parse(IO.read(@@CONFIG_FILE))
    @@SEARCH_EXTRA_KEYWORDS=cfg['SEARCH_EXTRA_KEYWORDS'].split(",")
    @@SEARCH_URL=cfg['SEARCH_URL'].to_s
    @@API_KEY=cfg['API_KEY'].to_s
    @@SEARCH_ENGINE_ID=cfg['SEARCH_ENGINE_ID'].to_s
    @@PROFILES_PER_KEYWORD=cfg['PROFILES_PER_KEYWORD'].to_i
    @@TOP_SKILL_WINDOW=cfg['TOP_SKILL_WINDOW'].nil? ? 10 : cfg['TOP_SKILL_WINDOW'].to_i
    @@BOTTOM_SKILL_WINDOW=cfg['BOTTOM_SKILL_WINDOW'].nil? ? 10 : cfg['BOTTOM_SKILL_WINDOW'].to_i
    @@SEARCH_KEYWORD_ARR=IO.read(@@INPUT_FILE).split("\n")
    @@FUZZYNESS=cfg['FUZZYNESS'].nil? ? 1 : cfg['FUZZYNESS'].to_i   
  end

  #Quesry Google Custom Search Engine
  def self.run_search_query(basic_keyword,search_keyword,page_no) 
    search_keyword_complete="#{basic_keyword} + #{search_keyword}"
    client = Google::APIClient.new( :application_name => 'Linkedin Profile Scrapper',
    :application_version => '0.0.1',:key => @@API_KEY, :authorization => nil)
    search = client.discovered_api('customsearch')


    if page_no==0
      response = client.execute(
      :api_method => search.cse.list,
      :parameters => {
        'q' => search_keyword_complete,
        'cref' => @@SEARCH_URL,
        'cx' => @@SEARCH_ENGINE_ID,
        'exactTerms' => search_keyword
        })

      else 
        response = client.execute(
        :api_method => search.cse.list,
        :parameters => {
          'q' => search_keyword_complete,
          'cref' => @@SEARCH_URL,
          'cx' => @@SEARCH_ENGINE_ID,
          'exactTerms' => search_keyword,
          'start' => page_no.to_s
          })
        end

        return response.body

      end


      #Parse Linkedin public profile pages and fetch skills 
      def self.parse_profile_data(url,keyword,count)
        if @@PROFILES_DONE[url].nil?  and count<@@PROFILES_PER_KEYWORD
          data=Nokogiri::HTML(open(url))
          skills=data.css('#content').css('#profile-skills').css('.jellybean').text
          skills=skills.split(/\n+/).map{|elem| elem.gsub(/\s+/, "")}
          skills.each do |skill|
            if !skill.empty?
              @@USER_SKILLS[skill.to_s.downcase]= (@@USER_SKILLS[skill.to_s.downcase].to_i) + 1
            end 
          end
          count=count+1
          @@PROFILES_DONE[url]=1 
        end
        return count
      end 



      #output all urls by parsing the json data
      #ensure that the out put urls of the public profile has an exact keyword match
      def self.parse_search_engine_results(json_data,keyword)
        parse_data=JSON.parse(json_data)
        result_url=parse_data["items"]
        valid_url_arr=[]
        if result_url
          result_url.each do |elem| 
            if elem['pagemap']  
              if elem['pagemap']['hcard']
                if @@FUZZYNESS==1 or elem['pagemap']['hcard'].to_s.downcase.gsub(/\s+/, "").include? keyword.downcase.gsub(/\s+/, "")
                  valid_url_arr.push(elem['link'])
                end
              end
            end  
          end
        end
        return valid_url_arr
      end


      #Pretty Print Function to output data to a file
      def self.sort_data(top_k,bottom_k)

        ans_arr=@@USER_SKILLS.sort_by {|k, v| v}
        ans_arr=ans_arr.reverse
        top_skills=ans_arr.empty? ? []:ans_arr[0,top_k].map {|k,v| k }
        bottom_skills=ans_arr.empty? ? []:ans_arr[-bottom_k,bottom_k].map {|k,v| k }
        File.open(@@OUTPUT_FILE, "w+") do |f|
          f.puts("Top #{top_k} skills\n")
          f.puts(top_skills)
          f.puts("\n********************\n")
          f.puts("Bottom #{bottom_k} skills\n")
          f.puts(bottom_skills)
        end

        puts "**Execution Completed: Results have been written to the output file**"
      end


      #Main Execution Function
      def self.execute_call
        self.init_config   
        @@SEARCH_KEYWORD_ARR.each do |keyword|
          basic_keyword=@@SEARCH_EXTRA_KEYWORDS.join(" ")
          count=0
          index=0
          puts "Crawler working on Keyword: #{keyword}"
          while count<@@PROFILES_PER_KEYWORD
            raw_json_data=run_search_query(basic_keyword,keyword,index)
            parse_data=JSON.parse(raw_json_data)

            if parse_data['error'] and parse_data['error']['code']==403
              puts "Unable to fetch results form Google"
              puts "REASON: #{parse_data['error']['message']}"
              break
            end

            url_arr=parse_search_engine_results(raw_json_data,keyword)
            url_arr.each do |url|
              if !url.nil?
                count=parse_profile_data(url.to_s,keyword,count)
              end
            end

            if parse_data["queries"] 
              if  parse_data["queries"]["nextPage"]
                index=parse_data["queries"]["nextPage"][0]["startIndex"].to_i
              else
                break;
              end
            else
              break
            end
          end
          puts "Hurray!!! Scraping for Keyword: #{keyword} completed...\n"
        end
        sort_data(@@TOP_SKILL_WINDOW,@@BOTTOM_SKILL_WINDOW)
      end

    end

    LinkedinSearch.execute_call
