module KibanaHelpers
    def curl_from_kibana(kib_pod, username, token, query, hostname: 'logging-es', args: [], forward_ip: '127.0.0.1', bearer_token: nil, use_certs: true, omit_header: nil)
        bearer_token = token if bearer_token.nil?
        cmd = "curl --connect-timeout 1 -k -v -q"
        if use_certs
          cmd << " --cert /etc/kibana/keys/cert"
          cmd << " --key /etc/kibana/keys/key"
        end
        cmd << " -H 'x-proxy-remote-user: #{username}'" unless 'username' == omit_header
        cmd << " -H 'Authorization: Bearer #{bearer_token}'" unless 'token' == omit_header
        cmd << " -H 'X-Forwarded-For: #{forward_ip}'"
        cmd << " -H 'kbn-version: 4.6.4'"
        cmd << " #{args.join(' ')} https://#{hostname}:9200/#{query}"
        @oc.exec(kib_pod, cmd)
            .namespace(@namespace)
            .container('kibana')
            .token(token)
            .do().strip()
    end

    # return the response hash with count or error information
    def doc_count_from_kibana(kib_json, username, token, index, bearer_token: nil, use_certs: true, omit_header: nil)
      q="#{index}/_count"
      out = curl_from_kibana(kib_json.metadata.name, 
           username, token, q, bearer_token: bearer_token, use_certs: use_certs, omit_header: omit_header)
      if m = /HTTP\/1\.1 (?<code>\d*) (?<message>.*)/.match(out)
          return {'error'=>{'status'=>m[:code].to_i, 'message'=> m[:message]}}
      end
      JSON.parse(out)
    end

    def mget_from_kibana(kib_json, username, token, json_payload, hostname: 'logging-es', args: [])
      q='_mget?timeout=0&ignore_unavailable=true'
      args = ['-q',
              '-d', "'#{json_payload}'", 
          "-H 'content-type: application/json;charset=UTF-8'", 
          "-H 'Connection:keep-alive'",
          "-H 'content-length: #{json_payload.length}'"]
      JSON.parse(curl_from_kibana(kib_json.metadata.name, username, token, q, args: args, forward_ip: kib_json.status.podIP))
    end

    def msearch_from_kibana(kib_json, username, token, json_payload, hostname: 'logging-es', args: [], bearer_token: nil)
      bearer_token = token if bearer_token.nil?
      q='_msearch?timeout=0&ignore_unavailable=true'
      args = ['-q',
              '-d', "'#{json_payload}'", 
          "-H 'content-type: application/json;charset=UTF-8'", 
          "-H 'Connection:keep-alive'",
          "-H 'content-length: #{json_payload.length}'",
          "-H 'x-proxy-remote-user: #{username}'", 
          "-H 'Authorization: Bearer #{bearer_token}'"]
      JSON.parse(curl_from_kibana(kib_json.metadata.name, username, token, q, args: args, forward_ip: kib_json.status.podIP))
    end 

    def get_index_mapping(kib_json, username, token, id)
      doc = {}.tap do |h|
            h[:docs] = [].tap do |a|
                a << {}.tap do |r|
                    r['_index'] = '.kibana'
                    r['_type'] = 'index-pattern'
                    r['_id'] = id 
                end
            end
        end.to_json
      mget_from_kibana(kib_json, username, token, doc)
    end
end
