require "./lib/array_extension"
require "active_support"
require "active_support/core_ext"
require "json"
require "net/http"
require "uri"
require "pry"

# settings
PRODUCT_CODE = "FX_BTC_JPY"
BAND_COUNT = 20
INTERVAL = 1.hour
SD_LEVEL = 2

# https://lightning.bitflyer.jp/docs/playground?lang=ja
def board(product_code)
  uri = URI.parse("https://api.bitflyer.jp")
  uri.path = "/v1/board"
  uri.query = "product_code=#{product_code}"

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  response = https.get(uri.request_uri)
  JSON.parse(response.body)
end

prices = []

# BAND_COUNT ぶんの 移動平均を計算
puts "----#{BAND_COUNT}回、移動平均を計算します----"
BAND_COUNT.times do |i|
  current_mid_price = board(PRODUCT_CODE)["mid_price"]
  prices.push(current_mid_price)
  puts "#{i + 1}: ¥#{current_mid_price.to_i.to_s(:delimited)}"
  sleep(INTERVAL)
end

str = <<-EOS
-----#{BAND_COUNT} 回の平均値の計算完了-----

--------------------------
移動平均値: #{prices.ave}
標準偏差(α): #{prices.sd}
--------------------------

実際の売り買いの判定処理に移ります。

.
.
.

EOS
puts str

# 以降の処理は BAND_COUNT 数の配列を保ちつつ、実際に売り買いの判定を行います。
while(1)
  current_mid_price = board(PRODUCT_CODE)["mid_price"]
  prices.push(current_mid_price)
  prices.shift

  ave = prices.ave # 移動平均
  sd  = prices.sd # 標準偏差

  puts "-------------------------------"
  str = <<-EOS
  ただいまの価格は ¥#{current_mid_price.to_i.to_s(:delimited)} です。

  --------------------------
  移動平均値: #{ave}
  標準偏差(α): #{sd}
  --------------------------
  EOS
  puts str

  # ボリンジャーバンドの SD_LEVEL(n 次)判定を行い、売り買いの判断を下す
  _price = current_mid_price.to_i.to_s(:delimited)
  top_line = ave + SD_LEVEL * sd
  bottom_line = ave - SD_LEVEL * sd

  str = <<-EOS
  #{SD_LEVEL}α のボリンジャーバンド:
  ¥#{bottom_line.to_i.to_s(:delimited)} 〜 ¥#{top_line.to_i.to_s(:delimited)}

  現在の価格: ¥#{_price}
  EOS
  puts str

  if current_mid_price >= top_line
    puts "  バンドを上回ったため売り注文"
  elsif current_mid_price < bottom_line
    puts "  バンドを下回ったため買い注文"
  else
    puts "  バンドの範囲内のため何もしない"
  end
  puts "-------------------------------"
  sleep(INTERVAL)
end
