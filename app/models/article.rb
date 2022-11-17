class Article < ApplicationRecord
  has_paper_trail on: [:update, :create]
  has_one_attached :cover
  
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :category
  
  has_many :tags
  has_many :comments, as: :commentable, dependent: :destroy

  accepts_nested_attributes_for :tags, :comments

  validates :title, presence: true
  validates :description, presence: true

  enum status: %i[published hidden], _default: "published"

  scope :not_deleted, lambda { where(deleted_at: nil) }
  scope :deleted, lambda { where("#{self.table_name}.deleted_at IS NOT NULL") }

  STATUS = %w{ published hidden }

  STATUS.each do |status_article|
    define_method "#{status_article}?" do 
      status == status_article  
    end
  end

  def self.filtered(params, current_user)
    scope = params[:article_deleted].present? ? Article.deleted.limit(10) : Article.not_deleted.limit(10)
    scope = scope.where('title ILIKE ?', "%#{params[:title].strip}%") if params[:title].present?
    scope = scope.joins(:author).where(author: {first_name: "%#{params[:first_name].strip}%"}) if params[:first_name].present?
    scope = scope.joins(:author).where(author: {last_name: "%#{params[:last_name].strip}%"}) if params[:last_name].present?
    scope = scope.joins(:category).where(category: {name: "%#{params[:name].strip}%"}) if params[:category_name].present?
    scope = scope.joins(:tags).where(tags: {name: "%#{params[:name].strip}%"}) if params[:tag_name].present?
    scope = scope.where(created_at: Date.strptime("#{params[:date].strip}}", "%d-%m-%y").all_day) if params[:date]
    scope = params[:per_page].present? ? scope.limit(params[:per_page].to_i) : scope.group(:id)
  end

  def destroy
    self.update(deleted_at: DateTime.current)
  end

  def delete
    destroy
  end

  def deleted?
    self.deleted_at.present?
  end
end
