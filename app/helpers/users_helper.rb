module UsersHelper
   def followees_list f, me, channels
     # followee_tokens is a virtual attribute, an array of booleans for checking and unchecking followees
     f.fields_for :followee_tokens do |builder|
   	   me.friend_candidates(channels).map { |other|
   		 builder.check_box(other.id.to_s, :checked => me.follows?(other.id)) + builder.label(other.id.to_s, other.username)
   	   }.compact.join('<br>').html_safe
     end
   end
   
   def login_choices user
       both = !(user.username.empty? || user.email.empty?)
       ((both ? "either " : "")+
       (user.username ? "your username '#{user.username}'" : "")+
       (both ? " or " : "")+
       (user.email ? "your email '#{user.email}'" : "")).html_safe
   end
end
