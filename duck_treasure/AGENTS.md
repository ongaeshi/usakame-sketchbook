# AGENTS.md (DUCK_TREASURE)

このプロジェクトはレトロゲームエンジン **Usakame (`uk`)** で作成された Ruby ゲームプロジェクトです。
AI エージェントがコードの生成・編集・デバッグを行う際は、以下のガイドラインを必ず遵守してください。

---

## 1. ドキュメント（編集前に必ず確認すること）

Usakame のスクリプト実行環境は軽量 Ruby VM **mrubyedge** です。標準の CRuby とは利用できる組み込みメソッドが異なります。
コードを記述する前に必ず以下のローカルドキュメントを参照してください。

* **[docs/mrubyedge_api.md](docs/mrubyedge_api.md)**: mrubyedge で利用可能な Ruby 標準クラス・メソッド一覧、および未実装メソッドと代替コード集。
* **[docs/api.md](docs/api.md)**: Usakame エンジン固有の描画・入力・タイルマップ・バンク・サウンド API（`cls`, `spr`, `blt`, `btn`, `map`, `sfx`, `music` 等）。
* **`refs/examples/*.rb`**（存在する場合、または `uk examples refs/examples` でいつでも展開可能）: 実践的なサンプルゲーム群（アクション、サバイバー、RPG、エディタ等）。

---

## 2. ⚠️ Ruby コード作成・編集時の絶対ルール（最重要）

以下のメソッドは **mrubyedge に存在しないため呼び出すと `NoMethodError` でクラッシュします**。必ず記載の代替パターンを使用してください。

* ❌ `array.sample` → ⭕ **`array[rand(array.size)]`**
* ❌ `array.shuffle` → ⭕ ランダムスワップ処理を自前で実装する
* ❌ `array.reverse` → ⭕ インデックスを逆順に回す（`i = array.size - 1; while i >= 0 ...`）
* ❌ `array.delete(item)` → ⭕ **`array.reject! { |x| x == item }`** または `delete_at(idx)`
* ❌ `hash.key?(k)` / `include?` → ⭕ **`hash.has_key?(k)`**
* ❌ `hash.dig(...)` → ⭕ `hash[a] && hash[a][b]`
* ❌ `string.gsub` / `sub` → ⭕ `string.split(pat).join(rep)` 等で代替
* ❌ `n.upto(m)` / `downto` → ⭕ **`(n..m).each`** または `while` ループ
* ❌ `n.even?` / `odd?` → ⭕ **`n % 2 == 0`** / **`n % 2 != 0`**
* ❌ `sleep(sec)` / `Time.now` → ⭕ ゲームループ（毎フレーム呼ばれる `update`）内のフレームカウンタ変数で制御
* ❌ `require` / `load` / `eval` → ⭕ 単一スクリプト構成で記述する

### タイルマップ API（`mget` / `mset` / `mdel`）のルール
* **空マスの取得**: `mget(x, y)` は空マス・未設定セルに対して **`nil`** を返します（`-1` ではありません）。
  * ⭕ `if mget(x, y)` でタイルが存在するか判定できます（0番タイルも真になります）。
  * ❌ `if mget(x, y) > 0` や `if mget(x, y) != -1` と書かないこと。
* **タイルの消去**: 消去には **`mdel(x, y)`** または **`mset(x, y, nil)`** を使用してください（`-1` を渡すと `ArgumentError` になります）。

---

## 3. 実行・テスト・AI による自動視覚検証コマンド

* **🤖 高速ヘッドレス検証（構文 & 60フレーム実行チェック、推奨）**:
  GUI ウィンドウを開かずに一瞬（0.1秒未満）で構文エラーや実行時例外（`NoMethodError` 等）を検証できます：
  ```bash
  uk check game.rb
  # ガチャキーモード（方向キー・パッドボタンの擬似連打テスト）
  uk check game.rb -g --frames 120
  ```
  コードを生成・編集した直後は、まずこのコマンドを実行してクラッシュしないことを確認してください。
* **ゲームの起動（ホットリロード対応）**:
  ```bash
  uk run game.rb
  ```
* **ゲームとエディタ（スプライト／タイルマップ）の同時起動**:
  ```bash
  uk run_with_edit game.rb
  ```
* **スプライトエディタ／タイルマップエディタ単体起動**:
  ```bash
  uk edit spr game.rb
  uk edit map game.rb
  ```
* **🤖 AI エージェントによる自動動作確認 & スクリーンショット検証**:
  画面の描画結果を画像として自律確認したい場合は、以下を実行すると指定フレーム後に PNG を保存して自動終了します（構文エラーや実行時エラーがあれば標準エラー出力に表示されます）：
  ```bash
  uk run game.rb --screenshot screenshots/check.png --frames 60
  ```
  コードを変更した後はこのコマンドでクラッシュがないか・描画が意図通りかを自律的に確認してください。
* **リソース分離・結合・配布ビルド**:
  ```bash
  uk unpack game.rb        # __END__ リソースを .spr / .map / .sfx に分離
  uk pack game.rb          # .spr / .map / .sfx を game.rb の __END__ に統合
  uk build game.rb         # 単一実行ファイル (.exe) を生成
  uk browser game.rb       # ブラウザ (WASM) でホットリロード実行
  ```
