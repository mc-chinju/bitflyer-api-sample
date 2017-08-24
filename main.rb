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
INTERVAL = 1.minute
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
BAND_COUNT.times do
  current_mid_price = board(PRODUCT_CODE)["mid_price"]
  prices.push(current_mid_price)
  puts "ただいまの価格は ¥#{current_mid_price.to_i.to_s(:delimited)} です。"
  sleep(INTERVAL)
end

<<-EOS
  "#{BAND_COUNT}" 回の平均値の集計が完了しました。

  --------------------------
  移動平均値: "#{prices.average}"
  標準偏差(α): "#{prices.sd}"
  --------------------------

  実際の売り買いの判定処理に移ります。
EOS

# 以降の処理は BAND_COUNT 数の配列を保ちつつ、実際に売り買いの判定を行います。
while(1)
  current_mid_price = board(PRODUCT_CODE)["mid_price"]
  prices.push(current_mid_price)
  prices.shift

  ave = prices.average # 移動平均
  sd  = prices.sd # 標準偏差

  <<-EOS
    ただいまの価格は ¥"#{current_mid_price.to_i.to_s(:delimited)}" です。

    --------------------------
    移動平均値: "#{ave}"
    標準偏差(α): "#{sd}"
    --------------------------
  EOS

  # ボリンジャーバンドの SD_LEVEL(n 次)判定を行い、売り買いの判断を下す
  _price = current_mid_price.to_i.to_s(:delimited)
  if current_mid_price >= ave + SD_LEVEL * sd
    puts "¥#{_price} で売り注文"
  elsif current_mid_price < ave - SD_LEVEL * sd
    puts "¥#{_price} で買い注文"
  else
    puts "¥#{_price} では何もしない"
  end
  sleep(INTERVAL)
end
