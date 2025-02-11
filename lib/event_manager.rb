# ruby lib/event_manager.rb
# after setting up gems with bundler:
# bundle exec ruby lib/event_manager.rb


# Check if file exists:
#existence = File.exist? "event_attendees.csv"
#puts existence

# Display entire contents of file:
#contents = File.read('event_attendees.csv')
#puts contents

=begin
# ITERATION 0: LOADING A FILE
puts 'Event Manager Initialized!'
# Read file line by line:
# File.readlines will save each line as a separate item in an array.
# Iterate over each line with lines.each do |line|
  # Split at comma with line.split(",")
# Want to access first_Name, which is 3rd column, so index columns[2]
  # Ignore the header when displaying the names with:
    # next if line == " ,RegDate,first_Name,last_Name,Email_Address,HomePhone,Street,City,State,Zipcode\n"
      # problem with ^^ is that header could change
    # instead, use each_with_index to skip first row

lines = File.readlines('event_attendees.csv')
lines.each_with_index do |line, index|
  next if index == 0
  columns = line.split(",")
  name = columns[2]
  puts name
end
=end

=begin
# ITERATION 1: PARSING WITH CSV
require 'csv' # Tell ruby we want to load the CSV library
puts 'Event Manager Initialized!'

# Instead of read or readlines we use CSV's open method to load our file.
# We also identify that this file has headers.
#contents = CSV.open('event_attendees.csv', headers: true)
#contents.each do |row|
#  name = row[2]
#  puts name
#end

# CSV files have an option to access column values by their headers.
# Converting headers to symbols make column names more uniform and easier to remember.
  # Header first_Name will be converted to :first_name and HomePhone to :homephone
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = row[:zipcode] # Can easily access zipcodes now too.
  puts "#{name} #{zipcode}"
end
=end

# ITERATION 2: CLEANING UP OUR ZIP CODES
# Problem: some zip codes are not enough digits, some zip codes are missing.
  # 1. if we look at the data, most of the short ones start with 0.
    # this data was likely stored as an integer, so the leading zeros were removed.
  # 2. we'll use a default, bad zip code of "00000" for the missing ones.

=begin
require 'csv' 
puts 'Event Manager Initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
  
contents.each do |row|
  name = row[:first_name]
  zipcode = row[:zipcode] 

  # Helpful to express what we're trying to do in words.
  # Pseudocode for cleaning zip codes:
    # if the zip code is exactly five digits, assume it is ok
    # if the zip code is more than five digits, truncate it to the 1st five digits
    # if the zip code is less than five digits, add zeros to the front until it's five digits
  
  if zipcode.nil?
    zipcode = '00000' # add this to deal with missing zipcodes first so we don't get an error when evaluating with length
  elsif zipcode.length < 5 
    zipcode = zipcode.rjust(5, '0') # rjust to pad the string with zeros
  elsif zipcode.length > 5
    zipcode = zipcode[0..4] # slices to get first 5 characters (index 0 to 4)
  end

  puts "#{name} #{zipcode}"
end
=end

=begin
# ITERATION 2: continued...
require 'csv'

# Move zipcode cleaning logic to its own method.
def clean_zipcode(zipcode)
#  if zipcode.nil?
#    '00000'
#  elsif zipcode.length < 5
#    zipcode.rjust(5, '0')
#  elsif zipcode.length > 5
#    zipcode[0..4]
#  else
#    zipcode
#  end

  # for nil value, instead convert to string nil.to_s => ""
  # string#rjust does nothing when the string length is > 5, so we can apply it to both cases:
    # "123456".rjust(5, '0') => "123456"
  # string#slice does nothing to strings exactly 5 digits long, so we can apply it in cases where zipcode is 5+ digits
    # "12345"[0..4] => "12345"
  # combining all these ^^ together, can simplify clean_zipcode:
  zipcode.to_s.rjust(5, '0')[0..4]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode]) # Call our new method

  puts "#{name} #{zipcode}"
end
=end

=begin
# ITERATION 3: USING GOOGLE'S CIVIC INFORMATION
# Using their zipcode and Google Civic's Information API webservice,
  # we are able to query for the representatives of a given area.
# Resulting document is JSON formatted.
require 'csv'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
# here ^ we've embedded the API key directly in the source code
  # it's best practice to NOT do this. 
  # more info in the note in Iteration 3 section of TOP page

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  # begin and rescue handle errors (such as default zipcode 00000)
  # this is an Exception Class
  begin
  legislators = civic_info.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: ['legislatorUpperBody', 'legislatorLowerBody']
  )
  legislators = legislators.officials 
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end

  puts "#{name} #{zipcode} #{legislators}"
end
=end

=begin
# ITERATION 3: continued...
# the above code outputs the raw legislator object.
# We really want to capture the first and last name of each legislator.
# To do this, we can use Array#map, returning a new array of the data we want:
require 'csv'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
# here ^ we've embedded the API key directly in the source code
  # it's best practice to NOT do this. 
  # more info in the note in Iteration 3 section of TOP page

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials 

    # Get just data we want:
#   legislator_names = legislators.map do |legislator|
#     legislator.name
#   end

    # Can simplify ^^ further:
    legislator_names = legislators.map(&:name)

    legislators_string = legislator_names.join(", ") # to output names as comma-separated string instead of array
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end

  puts "#{name} #{zipcode} #{legislators_string}"
end
=end

=begin
# ITERATION 3: continued... again...
# Move displaying legislators to a method so our code clearly expresses what we're trying to accomplish.
# Method will accept single zip code as a parameter and return a comma-serpated string of legislator names.
# Additional benefit of this is that it encapsulates how we actually retrieve the names of legislators.
  # This will be of benefit later if we decide on an alternative to the google-api gem
  # or want to introduce a level of caching to prevent look ups for similar zip codes.
require 'csv'
require 'google/apis/civicinfo_v2'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  puts "#{name} #{zipcode} #{legislators}"
end
=end


=begin
# ITERATION 4: FORM LETTERS
# Can now generate a personalized call to action.
# Want to include a customized letter thanking each attendee for coming to the conference,
  # and providing them a list of their representatives.

# We *could* do this as a large string within the current application.
  # ex. form_letter = %{ HTML formatted template }
# But that's not good so instead we'll create a separate html file,
  # load our template into this file,
  # and replace respective values using gsub! and gsub.

require 'csv'
require 'google/apis/civicinfo_v2'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.html') # Load html template file.

contents.each do |row|
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  personal_letter = template_letter.gsub('FIRST_NAME', name) # Replace first name & return new copy, & save new personal version.
  personal_letter.gsub!('LEGISLATORS', legislators) # Then replace legislators.

  puts personal_letter
end
# ^^Flaws: using FIRST_NAME and LEGISLATORS might cause problems if this text appears in any of our templates.
  # if a person's name contained the word 'LEGISLATORS', when we do the second part
  # of the operation, that part of the person's name would also be replaced.
# Instead of building our own solution, let's seek one out.
=end


=begin
# ITERATION 4: continued...
# We'll use Ruby ERB: 
  # (Embedded Ruby) allows executing Ruby code inside text templates, generating dynamic content easily.
# Save new file as form_letter.erb
# Uses escape sequences:
  # <%= ruby code will execute AND show output %> 
  # <% ruby code will execute but NOT show output %>

# We now need to update our application to:
  # Require ERB library
  # Create ERB template from the contents of the template file
  # Simplify our legislators_by_zipcode to return the original array of legislators

# Outputting form letters to a file: (each file should be uniquely named)
  # Assign an ID for the attendee
  # Create an output folder
  # Save each form letter to a file based on the id of the attendee

  require 'csv'
  require 'google/apis/civicinfo_v2'
  require 'erb' # Require ERB library

  
  def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
  end
  
  # Simplified to return the original array of legislators
  def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
    begin
      civic_info.representative_info_by_address(
        address: zip,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
      ).officials
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
  end
  
  puts 'EventManager initialized.'
  
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  
  # Create ERB template from the contents of the template file
  template_letter = File.read('form_letter.erb') # Load file contents as a string
  erb_template = ERB.new template_letter # Provide them a parameter when creating the new ERB template
  

  contents.each do |row|
    id = row[0] # Assign an ID for the attendee
    name = row[:first_name]
  
    zipcode = clean_zipcode(row[:zipcode])
  
    legislators = legislators_by_zipcode(zipcode)
  
    form_letter = erb_template.result(binding)

    Dir.mkdir('output') unless Dir.exist?('output') # Create an output folder

    filename = "output/thanks_#{id}.html" # Name each file based on the id of the attendee

    # Save each form to a file
    File.open(filename, 'w') do |file| # 1st parameter is file name. 2nd is a flag that states how we want to open the file; 'w' states we want to open the file for writing
      file.puts form_letter # This actually send the entire form letter content to the file object
    end

  end
=end

=begin
# ITERATION 4: continued... again...

# Move form letter generation to a method.

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

  
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end
  
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end
  
# Move personalized letter logic to a method
def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html" 

  File.open(filename, 'w') do |file| 
    file.puts form_letter 
  end
end

puts 'EventManager initialized.'
  
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
  
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
  

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])  
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter) # Call new method
end
=end

=begin
# ASSIGNMENT PT.1: CLEAN PHONE NUMBERS
# Need to make sure all phone numbers are valid and well-formed.
  # If less than 10 digits, assume it's bad
  # If 10 digits, assume it's good
  # If 11 digits & first digit is 1, trim the 1
  # If 11 digits & first digit is not 1, assume it's bad
  # If more than 11 digits, assume it's bad

require 'csv'
require 'google/apis/civicinfo_v2'


def clean_homephone(homephone)
  return '0000000000' if homephone.nil? # Deal with empty field

  homephone = homephone.gsub(/\D/, '') # Remove non-digits

  if homephone.length == 11 && homephone[0] == '1'
    homephone = homephone[1..] # Trim leading '1' if 11 digits and has leading 1
  end

  homephone.length == 10 ? homephone : '0000000000' # After checking above conditions... if it's 10 digits, return it. otherwise, return '0000000000'
end


contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  homephone = clean_homephone(row[:homephone])

  puts "#{name} #{homephone}"
end
=end

=begin
# ASSIGNMENT PT.2: TIME TARGETING
# Using registration date and time, we want to find out what the peak registration hours are

require 'csv'
require 'google/apis/civicinfo_v2'
#require 'time'

hours = []

def peak_times(hours)
  hours = hours.sort
  counts = hours.each_with_object(Hash.new(0)) { |num, hash| hash[num] += 1 } 
  sorted_counts = counts.sort { |a, b| b[1] <=> a[1] }
  sorted_counts.each { |num, count| puts "#{count} registrations at #{num}:00"}
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  regdate = Time.strptime(row[:regdate], '%m/%d/%y %H:%M')
  hours << regdate.strftime('%H').to_i

  #puts "#{hours}"
end

puts "#{hours}"
peak_times(hours)
=end


# ASSIGNMENT PT.3: DAY OF THE WEEK TARGETING
# What days of the week did most people register?
require 'csv'
require 'google/apis/civicinfo_v2'


contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

weekdays = []

def peak_days(weekdays)
  counts = {}
  days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  
  days.each do |day|
    counts[day] = weekdays.count(day)
  end
  sorted_counts = counts.sort_by { |_, count| -count }
  sorted_counts.each { |day, count| puts "#{count} registrations on a #{day}"}
end

contents.each do |row|
  weekdays << Time.strptime(row[:regdate], '%m/%d/%y %H:%M').strftime('%A')

end

#puts "#{weekdays}"
peak_days(weekdays)