# frozen_string_literal: true

namespace :huffman do
	desc 'Generate the huffman state table'
	task :generate_table do
		require_relative 'huffman'
		
		Huffman::Node.generate_state_table
	end
end
