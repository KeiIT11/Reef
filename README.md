## このプロジェクトについて
Reefは「あなたの努力をブロックチェーンに刻むアプリ」です。  
努力の内容が半永久的に保存されるので、あなたの努力内容が後世に残ります。  
あなたがおじいちゃんになった時に、孫に、自分の努力を自慢できるかもしれません。  
また、考えてみて欲しいのですが、もし、アインシュタインなどの天才が人生の時間をどのように使ってたのかわかったら面白いと思いませんか？  
Reefはこのような未来を実現可能にします。  
- 使用技術：Solidity, Dart, Flutter, sqflite
- 開発期間：2週間  
- 担当　　：全部  

<img src="https://user-images.githubusercontent.com/81548811/229280272-a545c47c-d3fc-4abb-a88a-0c979bcf79b3.PNG" alt="timer" width="20%"> <img src="https://user-images.githubusercontent.com/81548811/229280274-1af5b461-0cda-4895-8337-0aecc634cecf.PNG" alt="store data" width="20%"> <img src="https://user-images.githubusercontent.com/81548811/229280279-f70c39d5-2e88-4067-815d-a66b36f3e533.PNG" alt="look at" width="20%">

## 発表資料
海外のハッカソンだったので、英語でプレゼン・スピーチをし、説明も英語で書きました。

https://user-images.githubusercontent.com/81548811/229339372-9757f7ee-da47-47bf-900f-f02ba7d0d463.mp4

（容量の関係で２倍速になっています。）

Youtube: https://www.youtube.com/watch?v=pMXNUwuV7m4&ab_channel=keiit  
ProjectURL: https://devfolio.co/projects/reef-record-your-efforts-on-blockchain-680a  

## 使い方
### ローカルで実行
```
git clone ~.git
flutter clean
flutter packages get
flutter run
```

## 機能と使用技術（特徴を箇条書きなど）
### 1. タイマー機能

<img src="https://user-images.githubusercontent.com/81548811/229280272-a545c47c-d3fc-4abb-a88a-0c979bcf79b3.PNG" alt="timer" width="20%">

タスクを選択し、勉強時間を記録しながら勉強できます。ポモドーロテクニックで勉強を効率よく進めることができます。

### 2. ブロックチェーン保存機能

<img src="https://user-images.githubusercontent.com/81548811/229280274-1af5b461-0cda-4895-8337-0aecc634cecf.PNG" alt="store data" width="20%">

EthereumのGoerliテストネットワークに、勉強名と勉強時間を文字列で保存します。  
Dartで作成した内容をSolidityに変換する方法を工夫しました。配列で保存すると、ガス代が高くなってしまうため、文字列に変換して保存した。

ブロックチェーンに保存することで、得られるメリットとしては、
- サービス終了しても記録はが残る
- 他のサービスからもデータを参照できる  
などといったメリットがあります。

### 3. 検索機能

<img src="https://user-images.githubusercontent.com/81548811/229280279-f70c39d5-2e88-4067-815d-a66b36f3e533.PNG" alt="look at" width="20%">

見たい人のMetamaskの公開鍵を入力すると、その人の勉強記録が見れます。他のサービスからも閲覧可能です。
