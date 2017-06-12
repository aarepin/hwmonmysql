object azurehwmon: Tazurehwmon
  OldCreateOrder = False
  DisplayName = 'hwmontomysql'
  OnExecute = ServiceExecute
  Height = 459
  Width = 568
  object SQLC: TSQLConnection
    ConnectionName = 'MySQLConnection'
    DriverName = 'MySQL'
    Params.Strings = (
      'DriverName=MySQL'
      'HostName=10.0.8.7'
      'Database=repin'
      'User_Name=root'
      'Password=password'
      'ServerCharSet='
      'BlobSize=-1'
      'ErrorResourceFile='
      'LocaleCode=0000'
      'Compressed=False'
      'Encrypted=False'
      'ConnectTimeout=60')
    Left = 240
    Top = 40
  end
end
