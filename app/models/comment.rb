class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  field :content

  belongs_to :user
  belongs_to :post

  validates_presence_of :content, :user, :post
  validates_length_of :content, maximum: 10240

  after_create do
    user.karma += 1
    user.save
    return if user.id == post.user.id
    mention_new ["post","reply"]
  end

  after_destroy do
    user.karma -= 1
    user.save
  end

  private
  def mention_new types
    types.each do |type|
      mention = Mention.where(event: post.id, type: type).first
      if mention
        (mention.triggers << user.nick).uniq!
        mention.read = false
        mention.save
      else
        Mention.new(type: type, triggers: [user.nick], event: post.id, text: "post").deliver
      end
    end
  end
end

