note
	description: "[
			Abstract notion of a JSON deserialization class.
			]"
	what: "[
			A class capable of deserializing well-formed JSON and reconsituting or rehydrating an
			Eiffel class object from it.
			]"
	why: "[
			Various reasons, not the least of which are:
			
			1. Storage of complex object structures in RDBMS systems is a significant challenge
				that can be overcome by storing complex structures in JSON. Note that XML is 
				both verbose and difficult to use due to overburden of text and tags. JSON
				solves this issue by being terse. It also solves a problem that XML finds 
				difficulty in cleanly modeling complex object structures. JSON does not.
			2. JSON is a better choice for sending pure text data over the wire because of less
				text to send (about 30% lighter).
			]"
	EIS: "name=JSON Organization", "protocol=URI", "src=http://www.json.org"
	EIS: "name=Serialization (Deserialization)", "protocol=URI", "src=http://en.wikipedia.org/wiki/Serialization"
	how: "[
			Inherit from this class to make any other class deserializable from a well-formed JSON string.
			]"
	suppliers: "[
			BOOLEAN, CHARACTER_8, DATE, DATE_TIME, DECIMAL, 
				IMMUTABLE_STRING_8/32, STRING_8, , ARRAY/ARRAY_LIST
				INTEGER_8/16/32/64, MIXED_NUMBER, TUPLE
				NATURAL_8/16/32/64, REAL_32/64, TIME: Used for purposes of deserialization targets, defining
														how these types are deserialized from JSON representations
														to the Eiffel objects that they are, attaching their data
														to a target feature.
				
			JSON_ARRAY, JSON_BOOLEAN, JSON_NULL, 
				JSON_NUMBER, JSON_OBJECT, JSON_STRING, 
				JSON_VALUE: Various forms of JSON data types used in the conversion process (e.g. JSON_BOOLEAN --> BOOLEAN)
			
			JSON_PARSER: Used to parse the well-formed JSON string down to its JSON data type objects above.
			]"
	glossary: "[
			JSON: Java Script Object Notation. See: EIS-JSON Organization URI link (above).
			]"
	date: "$Date: 2015-12-31 07:55:33 -0500 (Thu, 31 Dec 2015) $"
	revision: "$Revision: 12934 $"

deferred class
	JSON_DESERIALIZABLE

inherit
	JSON_TRANSFORMABLE

feature {NONE} -- Initialization

	make_from_json (a_json: STRING)
			-- Initialize Current by parsing `a_json' and rehydrating it into Current.
		note
			what: "[
					Prototype creation procedure establishing that Deserializable things can be created from JSON strings.
					]"
			why: "[
					Objects must be deserializable by creation based on JSON strings.
					]"
			how: "[
					The JSON string in `a_json' is converted first to a JSON_OBJECT and then parsed to specific
					JSON things like arrays, strings, booleans, and so on. Those objects are then converted to
					the specific features, restoring the class to it original form at the point of serialization.
					]"
			BNF: "[]"
		require
			force_require_else_true_in_descendants: False
		deferred
		end

feature {NONE} -- Implementation: Basic Operations

	json_string_to_json_object (a_json: STRING): detachable JSON_OBJECT
			-- Parse `a_json' to its resulting JSON_OBJECT.
		local
			l_parser: JSON_PARSER
		do
			if a_json [a_json.count].is_control then
				from

				until
					not a_json [a_json.count].is_control
				loop
					a_json.remove_tail (1)
				end
			end
			if a_json [a_json.count] = ')' then
				a_json [a_json.count] := '}'
			end
			create l_parser.make_parser (a_json)
			if attached l_parser.parse_object as al_object then
				Result := al_object.twin
			end
		end

feature {NONE} -- Conversions: String

	json_object_to_json_string_representation (a_attribute_name: STRING; a_object: JSON_OBJECT): detachable STRING
			-- Deserialize actual STRING value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			if attached {JSON_NULL} a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) then
				Result := Void
			elseif attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation
				Result := strip_json_quotes (Result)
			end
		end

	json_object_to_json_string_representation_attached (a_attribute_name: STRING; a_object: JSON_OBJECT): STRING
			-- Deserialize actual STRING value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check attached json_object_to_json_string_representation (a_attribute_name, a_object) as al_attached_result then
				Result := al_attached_result
			end
		end

	json_object_to_json_immutable_string_representation (a_attribute_name: STRING; a_object: JSON_OBJECT): detachable IMMUTABLE_STRING_32
			-- Deserialize actual IMMUTABLE_STRING_32 for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			if attached {JSON_NULL} a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) then
				Result := Void
			elseif attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				create Result.make_from_string (strip_json_quotes (al_object.representation))
			end
		end

	json_object_to_json_immutable_string_representation_attached (a_attribute_name: STRING; a_object: JSON_OBJECT): IMMUTABLE_STRING_32
		do
			check attached json_object_to_json_immutable_string_representation (a_attribute_name, a_object) as al_attached_result then
				Result := al_attached_result
			end
		end

	recursive_json_object_to_json_string_representation (a_attribute_name: STRING; a_object: JSON_OBJECT): STRING
			-- Deserialize actual STRING value for `a_attribute_name' from `a_object', looking within interior JSON_OBJECTs.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			create Result.make_empty
			if attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation
			else
				across a_object as ic_object until not Result.is_empty loop
					if attached {JSON_OBJECT} ic_object.item as al_object then
						Result := recursive_json_object_to_json_string_representation (a_attribute_name, al_object)
					end
				end
			end
			if not Result.is_empty then
				Result := strip_json_quotes (Result)
			end
		end

feature {NONE} -- Conversions: Boolean

	json_object_to_boolean (a_attribute_name: STRING; a_object: JSON_OBJECT): BOOLEAN
			-- Deserialize actual BOOLEAN value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_boolean_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.same_string (json_true)
			end
		end

	recursive_json_object_to_boolean (a_attribute_name: STRING; a_object: JSON_OBJECT): BOOLEAN
			-- Deserialize actual BOOLEAN value for `a_attribute_name' from `a_object', looking within interior JSON_OBJECTs.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			if attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.same_string (json_true)
			else
				across a_object as ic_object until Result loop
					if attached {JSON_OBJECT} ic_object.item as al_object then
						Result := recursive_json_object_to_boolean (a_attribute_name, al_object)
					end
				end
			end
		end

feature {NONE} -- Conversions: Integer

	json_object_to_integer (a_attribute_name: STRING; a_object: JSON_OBJECT): INTEGER
			-- Deserialize actual INTEGER value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_integer_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_integer
			end
		end

	json_object_to_integer_8 (a_attribute_name: STRING; a_object: JSON_OBJECT): INTEGER_8
			-- Deserialize actual INTEGER_8 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_integer_8_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_integer_8
			end
		end

	json_object_to_integer_16 (a_attribute_name: STRING; a_object: JSON_OBJECT): INTEGER_16
			-- Deserialize actual INTEGER_16 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_integer_16_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_integer_16
			end
		end

	json_object_to_integer_32 (a_attribute_name: STRING; a_object: JSON_OBJECT): INTEGER_32
			-- Deserialize actual INTEGER_32 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_integer_32_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_integer_32
			end
		end

	recursive_json_object_to_integer_32 (a_attribute_name: STRING; a_object: JSON_OBJECT): INTEGER_32
			-- Deserialize actual INTEGER_32 value for `a_attribute_name' from `a_object', looking within interior JSON_OBJECTs.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			if attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_integer_32
			else
				across a_object as ic_object until Result > 0 loop
					if attached {JSON_OBJECT} ic_object.item as al_object then
						Result := recursive_json_object_to_integer_32 (a_attribute_name, al_object)
					end
				end
			end
		end

	json_object_to_integer_64 (a_attribute_name: STRING; a_object: JSON_OBJECT): INTEGER_64
			-- Deserialize actual INTEGER_64 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_integer_64_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_integer_64
			end
		end

feature {NONE} -- Conversions: Naturals

	json_object_to_natural_8 (a_attribute_name: STRING; a_object: JSON_OBJECT): NATURAL_8
			-- Deserialize actual NATURAL_8 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_natural_8_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_natural_8
			end
		end

	json_object_to_natural_16 (a_attribute_name: STRING; a_object: JSON_OBJECT): NATURAL_16
			-- Deserialize actual NATURAL_16 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_natural_16_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_natural_16
			end
		end

	json_object_to_natural_32 (a_attribute_name: STRING; a_object: JSON_OBJECT): NATURAL_32
			-- Deserialize actual NATURAL_32 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_natural_32_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_natural_32
			end
		end

	json_object_to_natural_64 (a_attribute_name: STRING; a_object: JSON_OBJECT): NATURAL_64
			-- Deserialize actual NATURAL_64 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_natural_64_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_natural_64
			end
		end

feature {NONE} -- Conversions: Real

	json_object_to_real_32 (a_attribute_name: STRING; a_object: JSON_OBJECT): REAL_32
			-- Deserialize actual REAL_32 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_real_32_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_real_32
			end
		end

	json_object_to_real_64 (a_attribute_name: STRING; a_object: JSON_OBJECT): REAL_64
			-- Deserialize actual REAL_64 value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check json_real_64_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				Result := al_object.representation.to_real_64
			end
		end

feature {NONE} -- Conversions: Date

	json_object_to_date (a_attribute_name: STRING; a_object: JSON_OBJECT): DATE
			-- Deserialize DATE value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			create Result.make_now
			check json_date_value: attached {JSON_STRING} a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_string then
				Result := json_string_to_date (al_string)
			end
		end

	json_string_to_date (a_json_string: JSON_STRING): DATE
			-- Deserialize actual DATE value from `a_json_string'.
		local
			l_string: STRING
			l_specification: LIST [STRING_8]
			l_dd, l_mm, l_yyyy: INTEGER
		do
			l_string := strip_json_quotes (a_json_string.representation)
			l_specification := l_string.split ('/')
			l_yyyy := l_specification.i_th (1).to_integer
			l_mm := l_specification.i_th (2).to_integer
			l_dd := l_specification.i_th (3).to_integer
			create Result.make_day_month_year (l_dd, l_mm, l_yyyy)
		end

feature {NONE} -- Conversions: Time

	json_object_to_time (a_attribute_name: STRING; a_object: JSON_OBJECT): TIME
			-- Deserialize TIME value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			create Result.make_now
			check json_time_value: attached {JSON_STRING} a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_string then
				Result := json_string_to_time (al_string)
			end
		end

	json_string_to_time (a_json_string: JSON_STRING): TIME
			-- Deserialize actual TIME value from `a_json_string'.
		local
			l_list: LIST [STRING]
			l_hours, l_minutes, l_seconds: INTEGER
			l_json_string: STRING
		do
			l_json_string := strip_json_quotes (strip_json_brackets (strip_json_percents (a_json_string.representation)))
			l_list := l_json_string.split ('/')
			l_hours := l_list.i_th (1).to_integer
			l_minutes := l_list.i_th (2).to_integer
			l_seconds := l_list.i_th (3).to_integer
			create Result.make (l_hours, l_minutes, l_seconds)
		end

feature {NONE} -- Conversions: Date-Time

	json_object_to_date_time (a_attribute_name: STRING; a_object: JSON_OBJECT): DATE_TIME
			-- Deserialize DATE_TIME value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			create Result.make_now
			check json_time_date_value: attached {JSON_STRING} a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_string then
				Result := json_string_to_date_time (al_string)
			end
		end

	json_string_to_date_time (a_json_string: JSON_STRING): DATE_TIME
			-- Deserialize actual DATE_TIME value from `a_json_string'.
		local
			l_list: LIST [STRING]
			l_json_string: STRING
			l_year, l_month, l_day, l_hour, l_minute: INTEGER
			l_second: REAL_64
		do
			l_json_string := strip_json_brackets (strip_json_quotes (a_json_string.representation.twin))
			l_list := l_json_string.split ('/')
			l_year := l_list.i_th (1).to_integer
			l_month := l_list.i_th (2).to_integer
			l_day := l_list.i_th (3).to_integer
			l_hour := l_list.i_th (4).to_integer
			l_minute := l_list.i_th (5).to_integer_32
			l_second := l_list.i_th (6).to_real
			create Result.make_fine (l_year, l_month, l_day, l_hour, l_minute, l_second)
		end

feature {TEST_SET_HELPER} -- Conversions: Decimal

	json_object_to_decimal (a_attribute_name: STRING; a_object: JSON_OBJECT): detachable DECIMAL
			-- Deserialize actual DECIMAL value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		local
			l_string: STRING
		do
			create Result
			create l_string.make_empty
			check attached {JSON_OBJECT} a_object as al_object then
				if attached {JSON_NULL} al_object.item (create {JSON_STRING}.make_json (a_attribute_name)) then
					Result := Void
				elseif attached {JSON_STRING} al_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_value then
					Result := json_string_to_decimal (al_value)
				end
			end
		end

	json_object_to_decimal_attached (a_attribute_name: STRING; a_object: JSON_OBJECT): DECIMAL
			-- Deserialize actual DECIMAL value for `a_attribute_name' from `a_object'.
		require
			non_empty_attribute_name: not a_attribute_name.is_empty
		do
			check attached_result: attached json_object_to_decimal (a_attribute_name, a_object) as al_attached_result then
				Result := al_attached_result
			end
		end

	json_string_to_decimal (a_json_string: JSON_STRING): DECIMAL
			-- Deserialize actual DECIMAL value from `a_json_string'.
		local
			l_string, l_value_string: STRING
			l_specification: LIST [STRING_8]
			l_exponent: INTEGER
		do
			l_string :=  strip_json_brackets (strip_json_quotes (a_json_string.representation))
			if l_string.occurrences (',') = 0 then
				create Result.make_from_string (l_string)
			else
				l_specification := l_string.split (',')
				create l_value_string.make_empty
				l_value_string.append_string (l_specification [2])
				if l_value_string.has_substring ("NaN") then
					create Result.make_from_string ("NaN")
				else
					l_exponent := l_specification [3].to_integer
					if l_exponent < 0 then
						l_value_string.prepend_string (create {STRING}.make_filled ('0', l_exponent.abs))
						l_value_string.insert_string (".", l_value_string.count + l_exponent + 1)
					end
					if l_specification [1].same_string ("1") then
						l_value_string.precede ('-')
					end
					create Result.make_from_string (l_value_string)
				end
			end
		end

feature {TEST_SET_BRIDGE} -- Conversions: Mixed Number

	json_string_to_mixed_number (a_json_array: JSON_ARRAY): FW_MIXED_NUMBER
			-- Deserialize actual MIXED_NUMBER value from `a_json_array'
		local
			l_negative: BOOLEAN
			l_whole: NATURAL_64
			l_numerator, l_denominator: NATURAL_32
		do
			check negative: attached {JSON_BOOLEAN} a_json_array.i_th (1) as al_json_null then
				if al_json_null.representation.same_string (Json_true) then
					l_negative := True
				end
			end
			check whole: attached {JSON_NUMBER} a_json_array.i_th (2) as al_whole then
				l_whole := al_whole.item.to_natural_64
			end
			check numerator: attached {JSON_NUMBER} a_json_array.i_th (3) as al_numerator then
				l_numerator := al_numerator.item.to_natural_32
			end
			check denominator: attached {JSON_NUMBER} a_json_array.i_th (4) as al_denominator then
				l_denominator := al_denominator.item.to_natural_32
			end
			create Result.make (l_negative, l_whole, l_numerator, l_denominator)
		end

feature {NONE} -- Conversions: Tuple

	json_object_to_tuple_as_json_array (a_attribute_name: STRING; a_object: JSON_OBJECT): JSON_ARRAY
			-- Deserialize actual TUPLE value for `a_attribute_name' from `a_object'.
		do
			create Result.make_empty
			if attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				if attached {JSON_ARRAY} al_object as al_array then
					Result := al_array
				elseif attached {JSON_STRING} al_object as al_string then
					Result.put_front (al_string)
				else
					check unknown_type: False end
				end
			end
		end

	json_object_to_json_array (a_attribute_name: STRING; a_object: JSON_OBJECT): JSON_ARRAY
			-- Deserialize actual ARRAY value for `a_attribute_name' from `a_object'.
		do
			create Result.make_array
			check json_array_value: attached a_object.item (create {JSON_STRING}.make_json (a_attribute_name)) as al_object then
				check array_string: attached {JSON_ARRAY} al_object as al_array then
					Result := al_array
				end
			end
		end

feature {NONE} -- Implementation

	strip_json_quotes (a_json_string: STRING): STRING
			-- Remove attribute quotes from `a_json_string'
		do
			Result := strip_json_head_and_tail (a_json_string, "%"", "%"")
		ensure
			quotes_removed: not (Result.starts_with ("%"") and Result.ends_with ("%""))
		end

	strip_json_escaped_characters (a_json_string: STRING): STRING
			-- Remove escaped characters from `a_json_string' added in {JSON_STRING}.escaped_json_string.
			-- TODO: Do we want to escape all characters from {JSON_STRING}.escaped_json_string?
		do
			Result := a_json_string
			Result.replace_substring_all ("\%"", "%"")
--			Result.replace_substring_all ("\\", "\")
--			Result.replace_substring_all ("\b", "%B")
--			Result.replace_substring_all ("\f", "%F")
--			Result.replace_substring_all ("\n", "%N")
--			Result.replace_substring_all ("\r", "%R")
--			Result.replace_substring_all ("\t", "%T")
		ensure
--			escaped_characters: not (Result.has_substring ("\r") or else Result.has_substring ("\n") or else Result.has_substring ("\f")  or else Result.has_substring ("\b") or else Result.has_substring ("\\") or else Result.has_substring ("\%""))
			escapted_characters: not Result.has_substring ("\%"")
		end

	strip_json_brackets (a_json_string: STRING): STRING
			-- Remove brackets from `a_string'
		do
			Result := strip_json_head_and_tail (a_json_string, "[", "]")
		ensure
			brackets_removed: not (Result.starts_with ("[") and Result.ends_with ("]"))
		end

	strip_json_percents (a_json_string: STRING): STRING
			-- Remove attribute quotes from `a_json_string'
		do
			Result := strip_json_head_and_tail (a_json_string, "%%", "%%")
		ensure
			quotes_removed: not (Result.starts_with ("%%") and Result.ends_with ("%%"))
		end

	strip_json_head_and_tail (a_json_string: STRING; a_head, a_tail: STRING): STRING
			-- Strips `a_character' from `a_json_string'.
		do
			Result := a_json_string.twin
			if Result.starts_with (a_head) and Result.ends_with (a_tail) then
				Result.remove_head (1)
				Result.remove_tail (1)
			end
		end

	to_decimal (a_tuple: STRING): DECIMAL
			-- Create a DECIMAL from `a_tuple'.
		local
			l_tuple, l_string_value: STRING
			l_list: LIST [STRING_8]
		do
			l_tuple := strip_json_brackets (a_tuple).twin
			l_list := l_tuple.split (',')
			create l_string_value.make_empty
			if l_list.i_th (1).same_string ("-1") then
				l_string_value.append_character ('-')
			end
			l_string_value.append (l_list.i_th (2))
			l_string_value.insert_character ('.', l_string_value.count + (l_list.i_th (3).to_integer) + 1)
			create Result.make_from_string (l_string_value)
		end

feature {NONE} -- Implementation: Constants

	json_true: STRING = "true"

	json_false: STRING = "false"

end
