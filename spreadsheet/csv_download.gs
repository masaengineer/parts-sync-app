/**
 * スプレッドシートを開いたときにカスタムメニューを追加します。
 */
function onOpen() {
  Logger.log('onOpen が呼び出されました');
  try {
    var ui = SpreadsheetApp.getUi();
    ui.createMenu('カスタムメニュー')
      .addItem('CSVをダウンロード', 'showSheetSelectionDialog')
      .addToUi();
    Logger.log('onOpen が完了しました');
  } catch (e) {
    Logger.log('onOpen でエラーが発生しました: ' + e.toString());
  }
}

/**
 * シート選択ダイアログを表示します。
 */
function showSheetSelectionDialog() {
  Logger.log('showSheetSelectionDialog が呼び出されました');
  try {
    // ダイアログを表示する前に進捗状況をリセットする
    var props = PropertiesService.getScriptProperties();
    props.setProperty('processingCurrent', '0');
    props.setProperty('processingTotal', '0');
    props.setProperty('processingSheetName', '');
    props.setProperty('processingTimestamp', '0');
    
    var htmlOutput = HtmlService.createHtmlOutput(createSheetSelectionHtml())
      .setWidth(400)
      .setHeight(500)
      .setTitle('処理するシートを選択');
    SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'シート選択');
    Logger.log('showSheetSelectionDialog が完了しました');
  } catch (e) {
    Logger.log('showSheetSelectionDialog でエラーが発生しました: ' + e.toString());
  }
}

/**
 * シート選択ダイアログのHTMLを作成します。
 * @return {string} HTMLコンテンツ
 */
function createSheetSelectionHtml() {
  Logger.log('createSheetSelectionHtml が呼び出されました');
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheets = ss.getSheets();

    // スタイルを定義
    var css = `
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 20px;
        }
        .sheet-list {
          max-height: 400px;
          overflow-y: auto;
          border: 1px solid #ddd;
          padding: 10px;
          margin-bottom: 15px;
        }
        .sheet-item {
          margin-bottom: 8px;
        }
        button {
          padding: 8px 12px;
          margin-right: 5px;
        }
        #loading-container {
          display: none;
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background-color: rgba(255, 255, 255, 0.8);
          z-index: 1000;
          justify-content: center;
          align-items: center;
          flex-direction: column;
        }
        .spinner {
          border: 5px solid #f3f3f3;
          border-top: 5px solid #3498db;
          border-radius: 50%;
          width: 50px;
          height: 50px;
          animation: spin 2s linear infinite;
          margin-bottom: 20px;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        .progress-text {
          font-size: 16px;
          margin-bottom: 10px;
        }
      </style>
    `;

    // シート選択リストを生成
    var sheetListHtml = '';
    for (var i = 0; i < sheets.length; i++) {
      var sheetName = sheets[i].getName();
      sheetListHtml += `
        <div class="sheet-item">
          <input type="checkbox" id="sheet${i}" value="${sheetName}">
          <label for="sheet${i}"> ${sheetName}</label>
        </div>
      `;
    }

    // HTML構造を生成
    var html = `
      <html>
        <head>${css}</head>
        <body>
          <div id="main-container">
            <h3>処理するシートを選択してください</h3>
            <div class="sheet-list">${sheetListHtml}</div>
            <div id="buttons-container">
              <button id="process-button" onclick="processSheets()">選択したシートを処理</button>
              <button onclick="google.script.host.close()">キャンセル</button>
            </div>
          </div>
          
          <div id="loading-container">
            <div class="spinner"></div>
            <div class="progress-text">処理中...</div>
            <div id="progress-current">0/0 シート処理済み</div>
            <div id="progress-sheet">処理を開始しています...</div>
          </div>
          
          <script>
            // 処理開始関数
            function processSheets() {
              // 選択されたシートを取得
              const checkboxes = document.querySelectorAll('input[type=checkbox]:checked');
              if (checkboxes.length === 0) {
                alert('少なくとも1つのシートを選択してください');
                return;
              }
              
              // 選択されたシート名の配列を作成
              const selectedSheets = Array.from(checkboxes).map(cb => cb.value);
              
              // ローディング表示を開始
              document.getElementById('main-container').style.display = 'none';
              document.getElementById('loading-container').style.display = 'flex';
              
              // 進捗状況のポーリングを開始
              startProgressPolling();
              
              // サーバーサイド処理を実行
              google.script.run
                .withSuccessHandler(handleSuccess)
                .withFailureHandler(handleError)
                .processSheets(selectedSheets);
            }
            
            // 進捗状況のポーリング
            let progressInterval = null;
            
            function startProgressPolling() {
              if (progressInterval) clearInterval(progressInterval);
              progressInterval = setInterval(updateProgress, 1000);
            }
            
            function stopProgressPolling() {
              if (progressInterval) {
                clearInterval(progressInterval);
                progressInterval = null;
              }
            }
            
            function updateProgress() {
              google.script.run
                .withSuccessHandler(function(status) {
                  if (status && status.total > 0) {
                    document.getElementById('progress-current').textContent = 
                      status.current + '/' + status.total + ' シート処理済み';
                    document.getElementById('progress-sheet').textContent = 
                      '処理中: ' + status.sheetName;
                  }
                })
                .getProcessingStatus();
            }
            
            // 処理成功時の処理
            function handleSuccess(result) {
              stopProgressPolling();
              document.body.innerHTML = result;
            }
            
            // エラー処理
            function handleError(error) {
              stopProgressPolling();
              document.getElementById('loading-container').style.display = 'none';
              document.getElementById('main-container').style.display = 'block';
              alert('エラーが発生しました: ' + error);
            }
          </script>
        </body>
      </html>
    `;

    Logger.log('createSheetSelectionHtml が完了しました');
    return html;
  } catch (e) {
    Logger.log('createSheetSelectionHtml でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * 処理の進捗状況を取得します。
 * クライアント側からの定期的な呼び出し用。
 * @return {Object} 進捗状況オブジェクト
 */
function getProcessingStatus() {
  try {
    var props = PropertiesService.getScriptProperties();
    var current = parseInt(props.getProperty('processingCurrent') || '0');
    var total = parseInt(props.getProperty('processingTotal') || '0');
    var sheetName = props.getProperty('processingSheetName') || '';
    var timestamp = props.getProperty('processingTimestamp') || '0';
    
    return {
      current: current,
      total: total,
      sheetName: sheetName,
      timestamp: timestamp
    };
  } catch (e) {
    Logger.log('getProcessingStatus でエラーが発生しました: ' + e.toString());
    return { error: e.toString() };
  }
}

/**
 * 選択されたシートを処理し、ダウンロードリンクを含むHTMLを返します。
 * @param {string[]} sheetNames 処理するシート名の配列
 * @return {string} ダウンロードリンクを含むHTML
 */
function processSheets(sheetNames) {
  Logger.log('processSheets が呼び出されました');
  try {
    // 進捗状況をリセット
    var props = PropertiesService.getScriptProperties();
    props.setProperty('processingCurrent', '0');
    props.setProperty('processingTotal', sheetNames.length.toString());
    props.setProperty('processingSheetName', '処理を開始します...');
    props.setProperty('processingTimestamp', new Date().getTime().toString());
    
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var allRows = [];
    var processedCount = 0;

    // CSVのヘッダー行を設定（すべてのシートで共通）
    var headerRow = [
      'order_number',
      'manufacturer_name',
      'purchase_price',
      'handling_fee',
      'option_fee',
      'sheet_name' // シート名を識別するための追加列
    ];
    allRows.push(headerRow);
    
    for (var i = 0; i < sheetNames.length; i++) {
      var sheetName = sheetNames[i];
      var sheet = ss.getSheetByName(sheetName);
      
      if (sheet) {
        // 進捗状況を更新
        updateProgress(i + 1, sheetNames.length, sheetName);
        
        var result = generateFilteredCSV(sheet);
        
        // 行を解析し、シート名を追加
        var csvLines = Utilities.parseCsv(result.csv);
        if (csvLines.length > 1) { // ヘッダー以外のデータがある場合
          // ヘッダー行はスキップ（初回のみallRowsに追加済み）
          for (var j = 1; j < csvLines.length; j++) {
            var row = csvLines[j];
            // シート名を追加
            row.push(sheetName);
            allRows.push(row);
          }
          processedCount++;
        }
      }
    }
    
    // すべてのデータを一つのCSVに変換
    var csvContent = allRows
      .map(function(r) {
        return r.map(csvEscape).join(',');
      })
      .join('\r\n');
    
    // ファイル名を生成
    var fileName = 'Wisewill 委託分データ まとめ.csv';
    
    // BOM付きUTF-8でCSVデータを作成
    var csvContentWithBOM = '\ufeff' + csvContent;
    var blob = Utilities.newBlob(csvContentWithBOM, 'text/csv', fileName);
    var file = DriveApp.createFile(blob);
    
    // 新しいスプレッドシートを作成
    var newSSName = 'Wisewill 委託分データ まとめ (' + Utilities.formatDate(new Date(), 'JST', 'yyyy-MM-dd HH:mm') + ')';
    var newSS = SpreadsheetApp.create(newSSName);
    var newSheet = newSS.getActiveSheet();
    
    newSheet.clear();
    newSheet.getRange(1, 1, allRows.length, allRows[0].length).setValues(allRows);
    
    // 1行目を太字にして固定
    newSheet.getRange(1, 1, 1, allRows[0].length).setFontWeight('bold');
    newSheet.setFrozenRows(1);
    
    var fileUrl = file.getDownloadUrl();
    var sheetUrl = newSS.getUrl();
    
    // 結果を表示するHTMLを生成
    var htmlContent = '<html><head>'
      + '<style>'
      + 'body { font-family: Arial, sans-serif; margin: 20px; }'
      + '.result-item { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }'
      + 'h3 { margin-top: 0; }'
      + 'button { padding: 8px 12px; }'
      + '.success-icon { color: #4CAF50; font-size: 18px; margin-right: 5px; }'
      + '</style>'
      + '</head><body>'
      + '<h2>処理結果 <span class="success-icon">✓</span></h2>';
    
    if (processedCount > 0) {
      htmlContent += '<p>処理完了: ' + processedCount + ' / ' + sheetNames.length + ' シートのデータをまとめました</p>'
        + '<p>合計行数: ' + (allRows.length - 1) + ' 行（ヘッダー行を除く）</p>'
        + '<div class="result-item">'
        + '<h3>まとめデータ</h3>'
        + '<p><a href="' + fileUrl + '" target="_blank">CSVダウンロード</a></p>'
        + '<p><a href="' + sheetUrl + '" target="_blank">Googleスプレッドシートを開く</a></p>'
        + '</div>';
    } else {
      htmlContent += '<p>処理できるシートがありませんでした。</p>';
    }
    
    htmlContent += '<div style="margin-top: 20px;">'
      + '<button onclick="google.script.host.close()">閉じる</button>'
      + '</div>'
      + '</body></html>';
    
    Logger.log('processSheets が完了しました');
    return htmlContent;
  } catch (e) {
    Logger.log('processSheets でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * 処理の進捗状況を更新します。
 * @param {number} current 現在処理中のインデックス
 * @param {number} total 全シート数
 * @param {string} sheetName 現在処理中のシート名
 */
function updateProgress(current, total, sheetName) {
  Logger.log('updateProgress が呼び出されました');
  try {
    // この関数は直接クライアントサイドに表示を更新するものではなく、
    // デバッグやログ目的で使用します。実際のUI更新はHTMLとJavaScriptで行われます。
    Logger.log('処理中: ' + current + '/' + total + ' - シート: ' + sheetName);
    
    // プロパティサービスに進捗状況を保存
    var props = PropertiesService.getScriptProperties();
    props.setProperty('processingCurrent', current.toString());
    props.setProperty('processingTotal', total.toString());
    props.setProperty('processingSheetName', sheetName);
    props.setProperty('processingTimestamp', new Date().getTime().toString());
    
    Logger.log('updateProgress が完了しました');
  } catch (e) {
    Logger.log('updateProgress でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * ファイル名として安全な文字列にエスケープします。
 * @param {string} fileName エスケープするファイル名
 * @return {string} エスケープされたファイル名
 */
function escapeFileName(fileName) {
  Logger.log('escapeFileName が呼び出されました');
  try {
    // ファイル名に使用できない文字を置換
    var result = fileName.replace(/[/\\?%*:|"<>]/g, '_');
    Logger.log('escapeFileName が完了しました');
    return result;
  } catch (e) {
    Logger.log('escapeFileName でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * 指定されたシートからデータをフィルタリングし、CSV形式の文字列とシート名を返します。
 * @param {Sheet} sheet 処理するシート
 * @return {{csv: string, sheetName: string}} フィルタリングされたCSVデータとシート名を含むオブジェクト
 */
function generateFilteredCSV(sheet) {
  Logger.log('generateFilteredCSV が呼び出されました');
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var data = sheet.getDataRange().getValues();

    var result = [];
    // CSVのヘッダー行を変更
    result.push([
      'order_number',
      'manufacturer_name',
      'purchase_price',
      'handling_fee',
      'option_fee',
    ]);

    var orderNumberPattern = /^\d{2}-\d{5}-\d{5}$/;

    var colOrderNum = 1; // B列
    var colMarket = 2; // C列
    var colManu = 7; // H列
    var colPart = 8; // I列
    var colPurchase = 15; // P列
    var colHandling = 17; // R列
    var colOption = 18; // S列

    var sheetName = sheet.getName();
    var isMatome = sheetName.indexOf('まとめ専用') >= 0;

    // スキップカウントと最大スキップ行数を設定
    var skipCount = 0;
    var maxSkip = 50; // 無効行が50行連続したらループ終了

    // 日本語メーカー名と英語メーカー名の対応マップ
    const manufacturerNameMap = {
      トヨタ: 'toyota',
      ホンダ: 'honda',
      日産: 'nissan',
      三菱: 'mitsubishi',
      スバル: 'subaru',
      マツダ: 'mazda',
      スズキ: 'suzuki',
      レクサス: 'lexus',
      ダイハツ: 'daihatsu',
      いすゞ: 'isuzu',
      ヤマハ: 'yamaha',
    };

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var orderNumber = (row[colOrderNum] || '').toString().trim();
      if (!orderNumberPattern.test(orderNumber)) {
        // 無効行の場合
        skipCount++;
        if (skipCount > maxSkip) {
          // 一定数以上無効行が続いたため終了
          break;
        }
        continue;
      }
      // 有効行の場合はスキップカウントリセット
      skipCount = 0;

      var manufacturerName = (row[colManu] || '').toString().trim();
      var purchaseValue = (row[colPurchase] || '').toString().trim();
      var handling_fee = parseNumericOrZero(row[colHandling]);
      // 変数名を photo_fee から option_fee に変更
      var option_fee = parseNumericOrZero(row[colOption]);
      var market = (row[colMarket] || '').toString().trim();

      var purchase_price = 0;
      if (purchaseValue === '在庫') {
        var partStr = (row[colPart] || '').toString();
        var parts = extractAndCleanPartNumbers(partStr);
        if (parts.length > 0) {
          var foundPrice = searchPriceByPartNumber(ss, parts[0]);
          if (foundPrice === null) {
            continue;
          } else {
            purchase_price = foundPrice;
          }
        } else {
          continue;
        }
      } else {
        purchase_price = parseNumericOrZero(purchaseValue);
      }

      if (market === 'その他' && isMatome) {
        handling_fee += 1000;
      }

      // メーカー名を英語に変換 (対応マップに存在しない場合は元の日本語のまま)
      var englishManufacturerName =
        manufacturerNameMap[manufacturerName] || manufacturerName;

      // CSVに出力する配列の要素を変更
      result.push([
        orderNumber,
        englishManufacturerName,
        purchase_price,
        handling_fee,
        option_fee,
      ]);
    }

    var csv = result
      .map(function (r) {
        return r.map(csvEscape).join(',');
      })
      .join('\r\n');

    Logger.log('generateFilteredCSV が完了しました');
    return { csv: csv, sheetName: sheetName };
  } catch (e) {
    Logger.log('generateFilteredCSV でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * 文字列を数値に変換し、数値でない場合は0を返します。
 * @param {string|number} value 変換する値
 * @return {number} 変換された数値、または0
 */
function parseNumericOrZero(value) {
  Logger.log('parseNumericOrZero が呼び出されました');
  try {
    var v = (value || '').toString().trim().replace(/[¥,]/g, '');
    if (v === '') return 0;
    var num = Number(v);
    if (isNaN(num)) {
      return 0;
    }
    Logger.log('parseNumericOrZero が完了しました');
    return num;
  } catch (e) {
    Logger.log('parseNumericOrZero でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * CSV形式でエスケープが必要な文字をエスケープします。
 * @param {string} str エスケープする文字列
 * @return {string} エスケープされた文字列
 */
function csvEscape(str) {
  Logger.log('csvEscape が呼び出されました');
  try {
    str = (str || '').toString();
    if (str.indexOf(',') >= 0 || str.indexOf('"') >= 0) {
      str = '"' + str.replace(/\"/g, '""') + '"';
    }
    Logger.log('csvEscape が完了しました');
    return str;
  } catch (e) {
    Logger.log('csvEscape でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * 指定された品番に対応する価格をスプレッドシート全体から検索します。
 * @param {Spreadsheet} ss 検索対象のスプレッドシート
 * @param {string} partNumber 検索する品番
 * @return {number|null} 見つかった価格、またはnull
 */
function searchPriceByPartNumber(ss, partNumber) {
  Logger.log('searchPriceByPartNumber が呼び出されました');
  try {
    var sheets = ss.getSheets();
    for (var s = 0; s < sheets.length; s++) {
      var sheet = sheets[s];
      var data = sheet.getDataRange().getValues();
      var colPart = 8; // I列
      var colPurchase = 15; // P列
      for (var i = 1; i < data.length; i++) {
        var row = data[i];
        var rowParts = extractAndCleanPartNumbers(
          (row[colPart] || '').toString()
        );
        if (rowParts.indexOf(partNumber) >= 0) {
          var pVal = parseNumericOrZero(row[colPurchase]);
          if (pVal > 0) {
            Logger.log('searchPriceByPartNumber が完了しました');
            return pVal;
          }
        }
      }
    }
    Logger.log('searchPriceByPartNumber が完了しました');
    return null;
  } catch (e) {
    Logger.log('searchPriceByPartNumber でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * テキストから品番を抽出し、クリーンアップします。
 * @param {string} text 品番を含むテキスト
 * @return {string[]} クリーンアップされた品番の配列
 */
function extractAndCleanPartNumbers(text) {
  Logger.log('extractAndCleanPartNumbers が呼び出されました');
  try {
    var parts = [];
    var lines = text.toString().split(/\r?\n/);
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (!line) continue;
      line = line.replace(/^"(.*)"$/, '$1');

      var tokens = line.split(/\s+/);
      for (var j = 0; j < tokens.length; j++) {
        var token = tokens[j].trim();
        if (!token) continue;
        var cleaned = cleanPartNumber(token);
        if (cleaned) {
          parts.push(cleaned);
        }
      }
    }
    Logger.log('extractAndCleanPartNumbers が完了しました');
    return parts;
  } catch (e) {
    Logger.log('extractAndCleanPartNumbers でエラーが発生しました: ' + e.toString());
    throw e;
  }
}

/**
 * 品番をクリーンアップします（不要な文字を削除し、有効な形式かチェックします）。
 * @param {string} str クリーンアップする品番
 * @return {string} クリーンアップされた品番、または空文字列
 */
function cleanPartNumber(str) {
  Logger.log('cleanPartNumber が呼び出されました');
  try {
    str = str.replace(/^[\s　]+|[\s　]+$/g, '');
    if (!str) return '';

    str = str.replace(/[\(\（][^\)\）]*[\)\）]/g, '');
    str = str.replace(/在庫/g, '');
    str = str.replace(/→.*$/, '');
    str = str.replace(/\d+[個]/g, '');
    str = str.replace(/[０-９]+個/g, '');

    str = str.trim();

    var partNumberPattern = /^[A-Za-z0-9\-]+$/;
    if (!partNumberPattern.test(str)) {
      return '';
    }
    Logger.log('cleanPartNumber が完了しました');
    return str;
  } catch (e) {
    Logger.log('cleanPartNumber でエラーが発生しました: ' + e.toString());
    throw e;
  }
}
