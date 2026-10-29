# usakame-sketchbook 🎨🐰

Usakame (`uk`) で作成した試作品・プロトタイプ・ドット絵スケッチ・個人コレクション集です。

## 収録作品・スケッチ

| スクリプト | 概要 | 実行コマンド |
|:---|:---|:---|
| [`myroom.rb`](myroom.rb) | **MYROOM**: 2階建てモダンハウス探索＆レコード鑑賞ゲーム | `uk run myroom.rb` |
| [`duck_treasure.rb`](duck_treasure.rb) | **Duck Treasure**: アヒルの宝探しアクション | `uk run duck_treasure.rb` |
| [`big_ball.rb`](big_ball.rb) | **大玉転がし**: 32x32ドット絵の大玉と女の子のスプライト鑑賞デモ | `uk run big_ball.rb` |
| [`rpg_walk.rb`](rpg_walk.rb) | **RPG歩行**: 16ビットRPG風キャラクター（魔法少女／冒険者）の4方向歩行デモ | `uk run rpg_walk.rb` |
| [`duck.rb`](duck.rb) | **スイスイ泳ぐアヒルちゃん**: 16x16水泳アニメーション＆拡大プレビュー | `uk run duck.rb` |

## 作品ハイライト・詳細解説

### 🏠 MYROOM (`myroom.rb`)

2階建てのモダンな家を自由に歩き回り、家の中に散らばったレコードを集めてリビングのターンテーブルで音楽を流す探索＆チルゲームです。

- **部屋とフロアの構成**:
  - **1F**: キッチン＆ダイニング (西)、リビングルーム (中央)、サニーテラス (東)
  - **2F**: 寝室 (西)、書斎＆ロフト (中央)、星空バルコニー (東)
  - 画面端まで歩くと隣の部屋へ切り替わり、階段タイルに乗ることで1F／2Fをスムーズに行き来できます。
- **レコード収集＆音楽再生システム**:
  - 部屋のあちこちに置かれた全4枚のカラーバイナル（レコード）を回収できます。
  - 1Fリビング中央のターンテーブルの前でアクションキーを押すとレコードをセットして音楽が再生され、レコードの回転アニメーションや音符、イコライザーHUDが描画されます。
- **操作方法**:
  - **移動**: `方向キー` / `WASD`
  - **調べる / レコード取得 / 再生・曲送り**: `Z` または `Space`
  - **音楽停止**: `X`
- **エディタ連携**:
  - `uk edit map myroom.rb` や `uk edit spr myroom.rb` を使うことで、部屋の間取りや家具スプライトを直接編集できます。

## 実行方法

Usakame CLI (`uk`) を使用して実行します。

```bash
uk run myroom.rb
uk run duck_treasure.rb
uk run big_ball.rb
uk run rpg_walk.rb
uk run duck.rb
```
