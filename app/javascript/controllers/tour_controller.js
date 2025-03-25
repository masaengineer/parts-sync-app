import { Controller } from '@hotwired/stimulus';

// ツアー内容
const steps = [
  {
    title: 'ご登録ありがとうございます🎉',
    content: 'PartsSyncへようこそ！<p>まずは簡単に使い方をご案内します',
    order: 1,
  },
  {
    title: 'ダークモード切り替え機能',
    content:
      'アイコンをクリックすると、ダークモードのオンオフの切り替えができます。<br>Enterボタンで次に進めます💡',
    target: '#dark_change',
    order: 2,
  },
  {
    title: '注文フィルタ機能',
    content: '任意の注文をフィルタリングできます。',
    target: '#order_filter',
    order: 3,
  },
  {
    title: 'CSVインポート機能',
    content:
      '委託先のスプレッドシートのCSVファイルをインポートして、自動的に手数料を登録します。',
    target: '#csv_import_button',
    order: 4,
  },
  {
    title: '注文一覧機能',
    content: '1時間ごとに自動インポートされるeBay注文一覧を表示します。',
    target: '#order_table',
    order: 5,
  },
  {
    title: 'レポート切り替え機能',
    content:
      '月次レポートへ切り替えると、月ごとの年間収支を確認することができます。',
    target: '#report_change',
    order: 6,
  },
];

const tg = new tourguide.TourGuideClient({
  steps: steps,
  nextLabel: '次へ',
  prevLabel: '戻る',
  finishLabel: '終了',
  closeButton: true,
});

export default class extends Controller {
  connect() {
    if (!window.localStorage.hasOwnProperty('tg_tours_complete')) {
      tg.start();
    }
  }
}
