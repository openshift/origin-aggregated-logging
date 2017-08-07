module FileHelpers

    def dump_temp_yaml(content)
        file = Tempfile.new('logging')
        file.write(YAML.dump(content))
        file.fsync
        file
    end

end
