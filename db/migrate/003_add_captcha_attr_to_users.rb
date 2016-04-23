class AddCaptchaAttrToUsers < ActiveRecord::Migration
  def change
    add_column :users, :captcha_sid, :string
    add_column :users, :captcha_img, :string
  end
end
