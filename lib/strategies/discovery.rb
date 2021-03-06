module Intrigue
module Strategy
  class Discovery < Intrigue::Strategy::Base

    def self.recurse(entity, task_result)

      puts "RECURSING! #{entity}"

      if entity.type_string == "FtpServer"

        start_recursive_task(task_result,"ftp_banner_grab",entity,[])

      elsif entity.type_string == "DnsRecord"

        ### DNS Subdomain Bruteforce
        # Do a big bruteforce if the size is small enough
        if (entity.name.split(".").length < 3)
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true }])

          #start_recursive_task(task_result,"whois",entity)

        else
          # otherwise do something a little faster
          start_recursive_task(task_result,"dns_brute_sub",entity,[])
        end

      elsif entity.type_string == "IpAddress"

        start_recursive_task(task_result,"nmap_scan",entity)

        # Prevent us from hammering on whois services
        unless ( entity.created_by?("net_block_expand")||
                 entity.created_by?("masscan_scan") ||
                 entity.created_by?("nmap_scan") )
          start_recursive_task(task_result,"whois",entity)
        end

      elsif entity.type_string == "String"

        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, scan it
        if entity.details["whois_full_text"] =~ /#{task_result.scan_result.base_entity.name}/
          #start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 21}])
          #start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 443}])
          #start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 80}])
          #start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 8080}])
          #start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 8081}])
          #start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 8443}])
          start_recursive_task(task_result,"net_block_expand",entity, [])
        else
          puts "Cowardly refusing to expand this netblock."
        end


      elsif entity.type_string == "Uri"

        ## Grab the Web Server

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) #if entity.name =~ /^https/

        ## Spider, looking for metadata
        start_recursive_task(task_result,"uri_spider",entity,[
            {"name" => "threads", "value" => 1},
            {"name" => "max_pages", "value" => 100 },
            {"name" => "extract_dns_records", "value" => true},
            {"name" => "extract_dns_record_pattern", "value" => "#{task_result.scan_result.base_entity.name}"}]) unless entity.created_by? "uri_brute"

        # Check for exploitable URIs, but don't recurse on things we've already found
        start_recursive_task(task_result,"uri_brute", entity, [{"name"=> "threads", "value" => 1}, {"name" => "user_list", "value" => "admin, test"}]) unless entity.created_by? "uri_brute"

      else
        puts "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
