module ElasticsearchHelpers
    def exec_from_es(es_pod_name, token, cmd)
      @oc.exec(es_pod_name, cmd)
        .namespace(@namespace)
        .container('elasticsearch')
        .token(token)
        .do()
    end

    def index_exists?(es_pod_name, index, token: nil)
      token = @token if token.nil?
      out = exec_from_es(es_pod_name, token, "es_util --query=#{index} --head -i")
      /.*HTTP\/1\.1.200.*/.match(out).nil? == false
    end
    
    def delete_from_es(es_pod_name, token, index)
      exec_from_es(es_pod_name, token, "es_util --query=#{index} -XDELETE")
    end

    def query_from_es(es_pod_name, token, query)
      result = JSON.parse(exec_from_es(es_pod_name, token, "es_util --query=#{query}"))
      throw result if result['error']
      result
    end
end
