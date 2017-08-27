require 'slack-ruby-client'
require 'pp'
# slack.chat_postMessage(channel: '#questions_test', text: 'Hello World')
reminderTimes = {}

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

slack = Slack::Web::Client.new
client = Slack::RealTime::Client.new

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
end


client.on 'user_typing' do |data|
  if reminderTimes[data.user]
    # 3000*24=72000 seconds in a day
    if (Time.now.to_i - reminderTimes[data.user].to_i) > 69000
      client.message channel: "<@#{data.user}>", text: 'is this a dm?'
    end
  else
    reminderTimes[data.user] = Time.now
    user = slack.users_info(user: data.user).user
    slack.chat_postMessage channel: "@"+user.name, text: "Hey #{user.real_name}! \nI see you're typing in the #questions channel. \nI just wanted to remind you of the guidelines for effectively asking for help in an engineering setting. \n Make sure to be as clear as possible, the easier it is to understand the situation you're in - the faster someone in there can help you fix your issue. You can read more about how to clearly commuicate your programming issues here: https://stackoverflow.com/help/how-to-ask. \n\nThe recommended way to ask a question here at NYCDA would be to follow this template (feel free to copy paste): \n\n*What's wrong:* \n `(A clear description of the issue)` \n*This is the error message I'm getting:* \n `(Copy paste the error you got. Make sure to use three backticks to make it easier to read)` \n*I tried to:* \n `(A short description of what you tried to solve this problem. Including any resources you found online wouuld be great too!)` \n\nStructuring your question like this would let me know I should ping the TAs :smile:", as_user: false
  end
end

client.on "message" do |data|
  channel = slack.channels_info(channel: data.channel).channel
  user = slack.users_info(user: data.user).user
  text = data.text
  if (user.name != 'fizbot') and (channel.name == 'questions_test')
    if text.include? "What's wrong" or text.include? "This is the error message I'm getting" or text.include? "I tried to"
      slack.chat_postMessage channel: '#queue', text: "*New question from:* #{user.real_name}\n\n#{text}\n"
    end
  end

end

client.start!
