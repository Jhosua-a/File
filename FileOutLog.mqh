//+------------------------------------------------------------------+
//|                                                   FileOutLog.mqh |
//|                                                    Akimasa Ohara |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Akimasa Ohara"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Logging\FileLogger.mqh>

class FileOutLog
// 作成メモ : FileTxtのサブクラスとして作りたかったがスーパークラスに書き込みが前提となるため、メソッドをコピーし新たに作成
  {
protected:
   int MagicNumber; // システムID
   int LogLevel; // ログレベル 
   int FileHandle; // ファイルハンドル
   string FileName; // ファイル名
   int FlagsKind; // ファイルフラグ(FILE_READ（2:読み込み）, FILE_CSV（8:CSVファイル）等） 
   
public:
                     FileOutLog(int magicNum, int logLevel);
                    ~FileOutLog();
   //--- methods of access to protected data
   int               Handle(void)              const { return(FileHandle); };
//   string            FileName(void)            const { return(m_name);   };
   int               Flags(void)               const { return(FlagsKind);  };
   //--- general methods for working with files
   int               Open(int processID, const string file_name, int open_flags, const short delimiter);
   void              Close(int processID);
   void              Delete(int processID);
   void              Seek(int processID, const long offset,const ENUM_FILE_POSITION origin);
   //--- general methods for working with files
   void              Delete(int processID, const string file_name,const int common_flag=0);
   bool              IsExist(int processID, const string file_name,const int common_flag=0);
   
   uint              WriteString(int processID, const string value);
   string            ReadString(int processID);
   
   
   int ErrorCode; // エラーコード
   bool procResult; // 正常(0), 警告(1), エラー(2)
   
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FileOutLog::FileOutLog(int magicNum, int logLevel) : FileHandle(INVALID_HANDLE) ,FlagsKind(FILE_ANSI)
  {
   MagicNumber = magicNum;
   LogLevel = logLevel;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
FileOutLog::~FileOutLog()
  {
   // Close();
  }
//+------------------------------------------------------------------+
//| Open the file                                                    |
//+------------------------------------------------------------------+
int FileOutLog::Open(int processID, const string file_name, int open_flags, const short delimiter)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");

   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "Open", "-");
  
//--- check handle
   if(FileHandle!=INVALID_HANDLE)
      Close(processID);
//--- action
   if((open_flags &(FILE_BIN|FILE_CSV))==0)
      open_flags|=FILE_TXT;
//--- open

   // 処理前のエラーコードリセット
   ResetLastError();
   ErrorCode = 0;
   
   // ファイルオープン処理
   FileHandle=FileOpen(file_name, open_flags|FlagsKind, delimiter);
   
   // ファイルログクラスにファイルハンドルを設定
   fileLogger.setFileHandle(FileHandle);
   
   // ファイルオープン処理のエラーコードを取得
   int errorCode = GetLastError();
   ErrorCode = errorCode;
   
   // ログ出力
   if(errorCode == ERR_SUCCESS){
      fileLogger.debug(processID, false, "Open", "SUCCESS");
      procResult = 0;
   }else if(errorCode == ERR_TOO_MANY_FILES){
      fileLogger.error(processID, false, "Open", "ERR_TOO_MANY_FILES");
      Alert("【ERROR】64 を超えるファイルを同時に開く事は不可能");
      procResult = 2;
   }else if(errorCode == ERR_WRONG_FILENAME){
      fileLogger.error(processID, false, "Open", "ERR_WRONG_FILENAME");
      Alert("【ERROR】無効なファイル名");
      procResult = 2;
   }else if(errorCode == ERR_TOO_LONG_FILENAME){
      fileLogger.error(processID, false, "Open", "ERR_TOO_LONG_FILENAME");
      Alert("【ERROR】長すぎるファイル名");
      procResult = 2;
   }else if(errorCode == ERR_CANNOT_OPEN_FILE){
      fileLogger.error(processID, false, "Open", "ERR_CANNOT_OPEN_FILE");
      Alert("【ERROR】ファイルオープンエラー");
      procResult = 2;
   }else if(errorCode == ERR_FILE_CACHEBUFFER_ERROR){
      fileLogger.error(processID, false, "Open", "ERR_FILE_CACHEBUFFER_ERROR");
      Alert("【ERROR】読み込みのためにキャッシュに出来るメモリが不足");
      procResult = 2;
   }else{
      fileLogger.error(processID, false, "Open", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
      Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
      procResult = 2;
   }

   
   if(FileHandle!=INVALID_HANDLE)
     {
      //--- store options of the opened file
      FlagsKind|=open_flags;
      FileName=file_name;
     }
     
   // ログクラスのインスタンス削除
   delete fileLogger;
//--- result
   return(FileHandle);
  }

//+------------------------------------------------------------------+
//| Close the file                                                   |
//+------------------------------------------------------------------+
void FileOutLog::Close(int processID)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "Close", "-");
   
//--- check handle
   if(FileHandle!=INVALID_HANDLE){
      //--- closing the file and resetting all the variables to the initial state
      // 処理前のエラーコードリセット
      ResetLastError();
      ErrorCode = 0;
      
      // ファイルクローズ処理
      FileClose(FileHandle);
      
      // ファイルクローズ処理のエラーコードを取得
      int errorCode = GetLastError();
      ErrorCode = errorCode;
      
      // ログ出力
      if(errorCode == ERR_SUCCESS){
         fileLogger.debug(processID, false, "Close", "SUCCESS");
         procResult = 0;
      }else if(errorCode == ERR_INVALID_FILEHANDLE){
         fileLogger.debug(processID, false, "Close", "ERR_INVALID_FILEHANDLE");
//         Alert("【WARN】このハンドルを使用したファイルは閉じられた、または、初めから開けられませんでした");
         procResult = 1;
      }else if(errorCode == ERR_WRONG_FILEHANDLE){
         fileLogger.error(processID, false, "Close", "ERR_WRONG_FILEHANDLE");
         Alert("【ERROR】不正なファイルハンドル");
         procResult = 2;
      }else{
         fileLogger.error(processID, false, "Close", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
         Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
         procResult = 2;
      }
      
      
      // インスタンスのメンバリセット
      FileHandle=INVALID_HANDLE;
      FileName="";
      //--- reset all flags except the text
      FlagsKind&=FILE_ANSI|FILE_UNICODE;
   }else{
      ResetLastError();
      ErrorCode = 0;
      fileLogger.debug(processID, false, "Close", "INVALID_HANDLE");
//      Alert("【WARN】ファイルハンドルを持ち合わせていない");
      procResult = 1;
   }
     
     
   // ログクラスのインスタンス削除
   delete fileLogger;
  }

//+------------------------------------------------------------------+
//| Deleting an open file                                            |
//+------------------------------------------------------------------+
void FileOutLog::Delete(int processID)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "Delete", "-");
//--- check handle
   if(FileHandle!=INVALID_HANDLE){  
      string file_name=FileName;
      int    common_flag=FlagsKind&FILE_COMMON;
      
      //--- close before deleting
      Close(processID);
      
      // 処理前のエラーコードリセット
      ResetLastError();
      ErrorCode = 0;
      
      //--- delete
      // ファイル削除処理
      FileDelete(file_name,common_flag);
      
      // ファイル削除処理のエラーコードを取得
      int errorCode = GetLastError();
      ErrorCode = errorCode;
     
      // ログ出力
      if(errorCode == ERR_SUCCESS){
         fileLogger.debug(processID, false, "Delete", "SUCCESS");
         procResult = 0;
      }else if(errorCode == ERR_WRONG_FILENAME){
         fileLogger.error(processID, false, "Delete", "ERR_WRONG_FILENAME");
         Alert("【ERROR】無効なファイル名");
         procResult = 2;
      }else if(errorCode == ERR_CANNOT_DELETE_FILE){
         fileLogger.error(processID, false, "Delete", "ERR_CANNOT_DELETE_FILE");
         Alert("【ERROR】ファイル削除エラー");
         procResult = 2;
      }else{
         fileLogger.error(processID, false, "Delete", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
         Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
         procResult = 2;
      }   
      
      
   }else{
      ResetLastError();
      ErrorCode = 0;
      fileLogger.warn(processID, false, "Delete", "INVALID_HANDLE");
      Alert("【WARN】ファイルハンドルを持ち合わせていない");
      procResult = 1;
   }
   
   // ログクラスのインスタンス削除
   delete fileLogger;
  }


//+------------------------------------------------------------------+
//| Set position of pointer in file                                  |
//+------------------------------------------------------------------+
void FileOutLog::Seek(int processID, const long offset,const ENUM_FILE_POSITION origin)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "Seek", "-");
   
   
//--- check handle
   if(FileHandle!=INVALID_HANDLE){
      // 処理前のエラーコードリセット
      ResetLastError();
      ErrorCode = 0;
      
      // ポイント移動処理
      FileSeek(FileHandle,offset,origin);
      
      // ポイント移動処理のエラーコードを取得
      int errorCode = GetLastError();
      ErrorCode = errorCode;
      
      
      // ログ出力
      if(errorCode == ERR_SUCCESS){
         fileLogger.debug(processID, false, "Seek", "SUCCESS");
         procResult = 0;
      }else if(errorCode == ERR_FILE_NOT_EXIST){
         fileLogger.error(processID, false, "Seek", "ERR_FILE_NOT_EXIST");
         Alert("【ERROR】ファイルが不在");
         procResult = 2;
      }else{
         fileLogger.error(processID, false, "Seek", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
         Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
         procResult = 2;
      }
      
      
      
   }else{
      ResetLastError();
      ErrorCode = 0;
      fileLogger.warn(processID, false, "Close", "INVALID_HANDLE");
      Alert("【WARN】ファイルハンドルを持ち合わせていない");
      procResult = 1;
   }
   
   // ログクラスのインスタンス削除
   delete fileLogger;
  }
//+------------------------------------------------------------------+
//| Deleting a file                                                  |
//+------------------------------------------------------------------+
void FileOutLog::Delete(int processID, const string file_name,const int common_flag)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "Delete", "-");
   
//--- checking
   if(file_name==FileName)
     {
      int flag=FlagsKind&FILE_COMMON;
      if(flag==common_flag)
         Close(processID);
     }
//--- delete
   // 処理前のエラーコードリセット
   ResetLastError();
   ErrorCode = 0;  

   // ファイル削除処理
   FileDelete(file_name,common_flag);
   
   // ファイル有無チェック処理のエラーコードを取得
   int errorCode = GetLastError();
   ErrorCode = errorCode;
   
   // ログ出力
   if(errorCode == ERR_SUCCESS){
      fileLogger.debug(processID, false, "Delete", "SUCCESS");
      procResult = 0;
   }else if(errorCode == ERR_WRONG_FILENAME){
      fileLogger.error(processID, false, "Delete", "ERR_WRONG_FILENAME");
      Alert("【ERROR】無効なファイル名");
      procResult = 2;
   }else if(errorCode == ERR_CANNOT_DELETE_FILE){
      fileLogger.error(processID, false, "Delete", "ERR_CANNOT_DELETE_FILE");
      Alert("【ERROR】ファイル削除エラー");
      procResult = 2;
   }else{
      fileLogger.error(processID, false, "Delete", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
      Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
      procResult = 2;
   } 
   
   // ログクラスのインスタンス削除
   delete fileLogger;
  }
//+------------------------------------------------------------------+
//| Check if file exists                                             |
//+------------------------------------------------------------------+
bool FileOutLog::IsExist(int processID, const string file_name,const int common_flag)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "IsExist", "-");
  
   // 処理前のエラーコードリセット
   ResetLastError();
   ErrorCode = 0;  
   
   // ファイル有無チェック処理
   bool exist = FileIsExist(file_name,common_flag);
   
   // ファイル有無チェック処理のエラーコードを取得
   int errorCode = GetLastError();
   ErrorCode = errorCode;
   
   // ログ出力
   if(errorCode == ERR_SUCCESS){
      fileLogger.debug(processID, false, "IsExist", "SUCCESS");
      procResult = 0;
   }else if(errorCode == ERR_FILE_NOT_EXIST){
      fileLogger.debug(processID, false, "IsExist", "SUCCESS");
      procResult = 0;
   }else if(errorCode == ERR_DIRECTORY_NOT_EXIST){
      fileLogger.warn(processID, false, "IsExist", "ERR_DIRECTORY_NOT_EXIST");
      Alert("【WARN】ディレクトリ不在");
      procResult = 1;
   }else{
      fileLogger.warn(processID, false, "IsExist", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
      Alert("【WARN】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
      procResult = 1;
   }
   
   
   // ログクラスのインスタンス削除
   delete fileLogger;
   
   return(exist);
  }
//+------------------------------------------------------------------+
//| Writing string to file                                           |
//+------------------------------------------------------------------+
uint FileOutLog::WriteString(int processID, const string value)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "WriteString", "-");
//--- check handle
   if(FileHandle!=INVALID_HANDLE){
      // 処理前のエラーコードリセット
      ResetLastError();
      ErrorCode = 0;
      
      // 書き込み処理
      uint writeByte = FileWriteString(FileHandle, value);
      
      // 書き込み処理のエラーコードを取得
      int errorCode = GetLastError();
      ErrorCode = errorCode;
      
      // ログ出力
      if(errorCode == ERR_SUCCESS){
         fileLogger.debug(processID, false, "WriteString", "SUCCESS");
         procResult = 0;
      }else if(errorCode == ERR_WRONG_FILEHANDLE){
         fileLogger.error(processID, false, "WriteString", "ERR_WRONG_FILEHANDLE");
         Alert("【ERROR】不正なファイルハンドル");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTTOWRITE){
         fileLogger.error(processID, false, "WriteString", "ERR_FILE_NOTTOWRITE");
         Alert("【ERROR】ファイルは書き込むために開かれる必要があります");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTTXT){
         fileLogger.error(processID, false, "WriteString", "ERR_FILE_NOTTXT");
         Alert("【ERROR】ファイルはテキストとして開かれる必要があります。");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTTXTORCSV){
         fileLogger.error(processID, false, "WriteString", "ERR_FILE_NOTTXTORCSV");
         Alert("【ERROR】ファイルはテキストまたは CSV として開かれる必要があります");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTCSV){
         fileLogger.error(processID, false, "WriteString", "ERR_FILE_NOTCSV");
         Alert("【ERROR】ファイルは CSV として開かれる必要があります");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOT_EXIST){
         fileLogger.error(processID, false, "WriteString", "ERR_FILE_NOT_EXIST");
         Alert("【ERROR】	ファイルが不在");
         procResult = 2;
      }else if(errorCode == ERR_FILE_CANNOT_REWRITE){
         fileLogger.error(processID, false, "WriteString", "ERR_FILE_CANNOT_REWRITE");
         Alert("【ERROR】ファイルの書き換えが不可");
         procResult = 2;
      }else{
         fileLogger.error(processID, false, "WriteString", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
         Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
         procResult = 2;
      }
      
      
      return(writeByte);
      
   }else{
      ResetLastError();
      ErrorCode = 0;
      fileLogger.warn(processID, false, "WriteString", "INVALID_HANDLE");
      Alert("【WARN】ファイルハンドルを持ち合わせていない");
      procResult = 1;
   }
      
//--- failure
   // ログクラスのインスタンス削除
   delete fileLogger;
   
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Reading string from file                                         |
//+------------------------------------------------------------------+
string FileOutLog::ReadString(int processID)
  {
   // ファイルログクラスのインスタンス生成
   FileLogger *fileLogger = new FileLogger(MagicNumber, LogLevel, FileHandle, "FileOutLog");
   
   // ログ出力（処理開始）
   fileLogger.debug(processID, true, "ReadString", "-");
   
   
//--- check handle
   if(FileHandle!=INVALID_HANDLE){
      // 処理前のエラーコードリセット
      ResetLastError();
      ErrorCode = 0;
      
      // 読み込み処理（現在の位置から改行文字「\r\n」まで）
      string readTxt = FileReadString(FileHandle);
      
      // 読み込み処理のエラーコードを取得
      int errorCode = GetLastError();
      ErrorCode = errorCode;
      
      
      // ログ出力
      if(errorCode == ERR_SUCCESS){
         fileLogger.debug(processID, false, "ReadString", "SUCCESS");
         procResult = 0;
      }else if(errorCode == ERR_WRONG_FILEHANDLE){
         fileLogger.error(processID, false, "ReadString", "ERR_WRONG_FILEHANDLE");
         Alert("【ERROR】不正なファイルハンドル");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTTOWRITE){
         fileLogger.error(processID, false, "ReadString", "ERR_FILE_NOTTOWRITE");
         Alert("【ERROR】ファイルは書き込むために開かれる必要があります");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTTXT){
         fileLogger.error(processID, false, "ReadString", "ERR_FILE_NOTTXT");
         Alert("【ERROR】ファイルはテキストとして開かれる必要があります。");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTTXTORCSV){
         fileLogger.error(processID, false, "ReadString", "ERR_FILE_NOTTXTORCSV");
         Alert("【ERROR】ファイルはテキストまたは CSV として開かれる必要があります");
         procResult = 2;
      }else if(errorCode == ERR_FILE_NOTCSV){
         fileLogger.error(processID, false, "ReadString", "ERR_FILE_NOTCSV");
         Alert("【ERROR】ファイルはCSV として開かれる必要があります");
         procResult = 2;
      }else if(errorCode == ERR_FILE_READERROR){
         fileLogger.error(processID, false, "ReadString", "ERR_FILE_READERROR");
         Alert("【ERROR】ファイル読み込みエラー");
         procResult = 2;     
      }else if(errorCode == ERR_FILE_NOT_EXIST){
         fileLogger.error(processID, false, "ReadString", "ERR_FILE_NOT_EXIST");
         Alert("【ERROR】ファイルが不在");
         procResult = 2;
      }else if(errorCode == ERR_FILE_ENDOFFILE){
         fileLogger.warn(processID, false, "ReadString", "ERR_FILE_ENDOFFILE");
         Alert("【WARN】ファイルの終わりに達する為、CSVファイル(FileReadString、FileReadNumber、FileReadDatetime、FileReadBool)から次のデータを読み取ることができませんでした");
         procResult = 1;
      }else{
         fileLogger.error(processID, false, "ReadString", "OTHER_ERROR(" + IntegerToString(errorCode) + ")");
         Alert("【ERROR】その他のエラー(Code: " + IntegerToString(errorCode) + ")");
         procResult = 2;
      }
      
      return(readTxt);
   
   }else{
      ResetLastError();
      ErrorCode = 0;
      fileLogger.warn(processID, false, "ReadString", "INVALID_HANDLE");
      Alert("【WARN】ファイルハンドルを持ち合わせていない");
      procResult = 1;
   }
      
      
//--- failure
   // ログクラスのインスタンス削除
   delete fileLogger;
   
   return("");
  }