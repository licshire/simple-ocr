require 'open3'
require 'fileutils'

module OCR
	class Scan

		EXTENS = %w{pdf}

		# Initialize your Input File, Output File, Options, Type.
		#
		# @params [String, String, String, String] path to input file, path to output file, options of conversion (e.g. Language), output format of file.
		def initialize(input_file, output_file, options, type)
			@output_file = output_file
			@options = options
			@type = handle_output_type(type)
			@input_file = input_file
			if pdf?(input_file)
				@image = OCR::Path.new(input_file).image_path
				convert_to_img
			else
				@image = input_file
			end
			@clean_image = OCR::Path.new(output_file).clean_image_path
		end
		
		def handle_output_type(type)
			if type == :pdf
				'pdf'
			elsif type == :hocr
				'hocr'
			else
				nil.to_s
			end
		end

		# Conversion of PDF to Image
		def convert_to_img
			`gs -sDEVICE=png16m '-r#{OCR::MIN_DENSITY}' -o '#{@image}' '#{@input_file}'`
		end                                               

		# OCR of Input
		def scan_img
			clean_img
			`tesseract '#{@clean_image}' #{@options} '#{@output_file}' #{@type}`
			delete_files
		end

		# Execute Command
		def exec_command(command)
			Open3.popen3(command)
		end

		# Shell Script for cleaning the Image.
		def clean_img
			name = 'simple-ocr'
			g = Gem::Specification.find_by_name(name)
			`sh #{File.join(g.full_gem_path, 'lib/textcleaner')} -g -e stretch -f 25 -o 20 -t 30 -u -s 1 -T -p 20 '#{@image}' '#{@clean_image}'`
		end

		# Deleting unnecessary files after processing.
		def delete_files
			FileUtils.rm_rf(@clean_image)
			FileUtils.rm_rf(@image) if pdf?
		end

		def pdf?(input_file = @input_file)
			OCR::Path.new(input_file).name_exten[1] == OCR::Path::EXTENS[:pdf]
		end
	end
end
