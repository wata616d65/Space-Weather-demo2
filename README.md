# Space Weather App 🌌

宇宙天気による各種リスク（ドローン/コンパス、GPS/位置情報、通信/電波、航空/被ばく）をリアルタイムで予報・表示するFlutterアプリケーション。

![Flutter](https://img.shields.io/badge/Flutter-3.38.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 スクリーンショット

| ホーム画面 | 地点選択 |
|:---:|:---:|
| ダークテーマのメイン画面 | 地点登録・検索画面 |

## ✨ 機能

- 🎯 **4種類のリスク予報**: ドローン/コンパス、GPS、通信、被ばく
- 🌍 **地点登録**: 複数地点を登録して切り替え可能
- 📍 **現在地検索**: GPSで現在地を自動取得
- 🔄 **Light/Coreモード**: 一般向け簡易表示と専門家向け詳細表示
- 🌙 **ダークテーマ**: 宇宙をイメージしたデザイン

---

## 🚀 環境構築

### 必要条件

| 項目 | バージョン |
|------|-----------|
| Flutter | 3.38.x 以上 |
| Dart | 3.x 以上 |
| Android SDK | API 21 以上 |
| Java JDK | 17 |

### 1. Flutter SDKのインストール

```bash
# Flutter公式サイトからダウンロード
# https://docs.flutter.dev/get-started/install

# インストール確認
flutter doctor
```

### 2. リポジトリのクローン

```bash
git clone https://github.com/YOUR_USERNAME/space-weather-app.git
cd space-weather-app
```

### 3. 依存関係のインストール

```bash
flutter pub get
```

### 4. Supabase設定（オプション）

`lib/core/constants/api_constants.dart` を編集:

```dart
class ApiConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

---

## 🏃 実行方法

### Web版（推奨：すぐに動作確認可能）

```bash
flutter run -d chrome
# または
flutter run -d edge
```

### Android版

```bash
# エミュレータを起動
flutter emulators --launch <emulator_id>

# アプリを実行
flutter run -d <device_id>

# デバイス一覧を確認
flutter devices
```

### APKビルド

```bash
# デバッグ版
flutter build apk --debug

# リリース版
flutter build apk --release
```

生成されたAPK: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 プロジェクト構成

```
lib/
├── main.dart                  # エントリーポイント
├── app.dart                   # MaterialApp定義
├── core/
│   ├── constants/             # 定数（API URL等）
│   ├── theme/                 # テーマ定義
│   └── utils/                 # ユーティリティ
├── data/
│   ├── datasources/           # API Client, LocalStorage
│   └── repositories/          # Repository実装
├── domain/
│   ├── entities/              # データモデル
│   └── services/              # ビジネスロジック（RiskCalculator）
└── presentation/
    ├── providers/             # Riverpod Provider
    ├── screens/               # 画面
    └── widgets/               # 再利用可能ウィジェット
```

---

## 🛠️ トラブルシューティング

### Gradleビルドエラー

```bash
# キャッシュクリア
flutter clean
flutter pub get

# Gradleキャッシュもクリア
rm -rf android/.gradle
rm -rf ~/.gradle/caches
```

### Android SDKエラー

`android/app/build.gradle.kts` を確認:

```kotlin
android {
    compileSdk = flutter.compileSdkVersion
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
}
```

### ADB接続問題

```bash
adb kill-server
adb start-server
adb devices
```

---

## 📦 使用パッケージ

| パッケージ | 用途 |
|-----------|------|
| flutter_riverpod | 状態管理 |
| supabase_flutter | バックエンド接続 |
| geolocator | GPS位置情報取得 |
| geocoding | 逆ジオコーディング |
| shared_preferences | ローカルストレージ |
| http | HTTP通信 |
| google_fonts | フォント |
| intl | 日付フォーマット |

---

## 🔧 開発環境設定

### 推奨IDE

- **Android Studio** (Flutter/Dartプラグイン)
- **VS Code** (Flutter Extension)

### VS Code拡張機能

```json
{
  "recommendations": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter"
  ]
}
```

---

## 📄 ライセンス

MIT License

---

## 🤝 コントリビューション

1. Fork
2. Feature Branch (`git checkout -b feature/amazing-feature`)
3. Commit (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request

---

## 📞 お問い合わせ

Issues または Pull Request でお気軽にどうぞ！
