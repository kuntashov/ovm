#Использовать fs

Перем СистемнаяИнформация;
Перем ЭтоWindows;
Перем Лог;

// Активирует указанную версию OneScript.
// Создает необходимые симлинки и оперирует PATH.
//
// Параметры:
//   ИспользуемаяВерсия - Строка - Алиас версии, которую необходимо активировать
//   ВыполнятьУстановкуПриНеобходимости - Булево - Флаг, управляющей запуском установки в случае, если активируемый
//                                                 алиас не установлен 
//
Процедура ИспользоватьВерсиюOneScript(Знач ИспользуемаяВерсия, Знач ВыполнятьУстановкуПриНеобходимости = Ложь) Экспорт
	
	Лог.Информация("Активация версии OneScript %1", ИспользуемаяВерсия);

	ПроверитьНаличиеИспользуемойВерсии(ИспользуемаяВерсия, ВыполнятьУстановкуПриНеобходимости);
	
	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	КаталогУстановкиВерсии = ОбъединитьПути(КаталогУстановки, ИспользуемаяВерсия);
	
	ПутьКОбщемуКаталогуOneScript = ОбъединитьПути(КаталогУстановки, "current");
	
	НадоВывестиИнформационноеСообщение = НЕ ФС.КаталогСуществует(ПутьКОбщемуКаталогуOneScript);

	СоздатьСимЛинкНаКаталог(ПутьКОбщемуКаталогуOneScript, КаталогУстановкиВерсии);
	ДобавитьКаталогBinВPath(ОбъединитьПути(ПутьКОбщемуКаталогуOneScript, "bin"));
	
	Если НадоВывестиИнформационноеСообщение Тогда
		Лог.Предупреждение("ВНИМАНИЕ: Переоткройте терминал после первого использования ovm use.");
	КонецЕсли;

	Лог.Информация("OneScript %1 активирован", ИспользуемаяВерсия);

КонецПроцедуры

// Выполнение необходимых операций для начала использования ovm в случае, если OneScript ранее был установлен
// с добавлением в PATH.
// Только для Windows.
//
Процедура ВыполнитьМиграцию() Экспорт

	Лог.Информация("Выполнение миграции системного OneScript");

	Если ЭтоWindows Тогда
		
		Лог.Отладка("Определяю путь к дефолтному oscript");
		
		Команда = Новый Команда;
		Команда.УстановитьКоманду("where");
		Команда.ДобавитьПараметр("oscript");
		Команда.УстановитьПравильныйКодВозврата(0);
		
		Команда.Исполнить();
		
		ВыводКоманды = Команда.ПолучитьВывод();
		Лог.Отладка(ВыводКоманды);
				
		ПутьКСистемномуOneScript = СтрПолучитьСтроку(ВыводКоманды, 1);
		Лог.Отладка("Путь к системному OneScript: %1", ПутьКСистемномуOneScript);

		Если СтрНайти(ПутьКСистемномуOneScript, "ovm") > 0 Тогда
			Лог.Информация("OneScript уже под контролем ovm");
			Возврат;
		КонецЕсли;
		
		ПутьКBinСистемногоOscript = Новый Файл(ПутьКСистемномуOneScript).Путь;
		
		Лог.Отладка("Установка переменных среды на уровне системы");
		
		ПеременнаяPATH = ПолучитьПеременнуюСреды("PATH", РасположениеПеременнойСреды.Машина);
		УстановитьПеременнуюСреды("PATH", "%OVM_OSCRIPTBIN%;" + ПеременнаяPATH, РасположениеПеременнойСреды.Машина);
		УстановитьПеременнуюСреды("OVM_OSCRIPTBIN", ПутьКBinСистемногоOscript, РасположениеПеременнойСреды.Машина);
		
		Лог.Отладка("Добавление ovm в автозапуск cmd");

		ТекстВычислениеPATH = "set PATH=%OVM_OSCRIPTBIN%;%PATH%";
		
		СтрокаЗапуска = СтрШаблон(
			"REG ADD ""HKCU\Software\Microsoft\Command Processor"" /v Autorun /t REG_SZ /f /d ""%1""",
			ТекстВычислениеPATH
		);
		
		Лог.Отладка("Строка запуска
					|%1", СтрЗаменить(СтрокаЗапуска, "%", "%%"));

		Команда = Новый Команда;
		Команда.УстановитьИсполнениеЧерезКомандыСистемы(Ложь);
		Команда.УстановитьСтрокуЗапуска(СтрокаЗапуска);
		Команда.УстановитьПравильныйКодВозврата(0);
		
		Команда.Исполнить();

		ВыводКоманды = Команда.ПолучитьВывод();
		Лог.Отладка(ВыводКоманды);
		
		Лог.Отладка("Добавление ovm в автозапуск powershell");
		
		ПутьКФайлу = ОбъединитьПути(
			СистемнаяИнформация.ПолучитьПутьПапки(СпециальнаяПапка.ПрофильПользователя),
			"Documents",
			"WindowsPowerShell",
			"profile.ps1"
		);
		
		ТекстВычислениеPATH = "set PATH=$OVM_OSCRIPTBIN;$PATH";
		ДобавитьТекстВНовыйИлиИмеющийсяФайл(ТекстВычислениеPATH, ПутьКФайлу);
		
	Иначе
		Сообщение = "На *nix системах выполнение команды migrate не требуется.";
		Лог.Информация(Сообщение);
		Возврат;
	КонецЕсли;

КонецПроцедуры

Процедура СоздатьСимЛинкНаКаталог(Знач Ссылка, Знач ПутьНазначения)
	
	ПутьКСсылке = Новый Файл(Ссылка).ПолноеИмя;
	ПутьККаталогуНазначения = Новый Файл(ПутьНазначения).ПолноеИмя;

	Лог.Отладка("Создаю символическую ссылку %1 на %2", ПутьКСсылке, ПутьККаталогуНазначения);

	Если ФС.КаталогСуществует(ПутьКСсылке) Тогда 
		
		Лог.Отладка("Удаляю старую символическую ссылку");

		Если ЭтоWindows Тогда 
			УдалитьФайлы(ПутьКСсылке); 
		Иначе 
			Команда = Новый Команда; 
			Команда.УстановитьКоманду("unlink");
			Команда.ДобавитьПараметр(ПутьКСсылке);
			Команда.УстановитьПравильныйКодВозврата(0);
			Команда.Исполнить();

			Лог.Отладка(Команда.ПолучитьВывод());
		КонецЕсли; 
	КонецЕсли;
	
	Лог.Отладка("Выполняю создание символической ссылки");
	
	Если ЭтоWindows Тогда
		Команда = Новый Команда;
		Команда.УстановитьКоманду("mklink");
		Команда.ДобавитьПараметр("/J");
		Команда.ДобавитьПараметр(ПутьКСсылке);
		Команда.ДобавитьПараметр(ПутьККаталогуНазначения);
		Команда.УстановитьПравильныйКодВозврата(0);
		
		Команда.Исполнить();
		Лог.Отладка(Команда.ПолучитьВывод());
	Иначе
		Команда = Новый Команда;
		Команда.УстановитьКоманду("ln");
		Команда.ДобавитьПараметр("-s");
		Команда.ДобавитьПараметр(ПутьККаталогуНазначения);
		Команда.ДобавитьПараметр(ПутьКСсылке);
		Команда.УстановитьПравильныйКодВозврата(0);
		
		Команда.Исполнить();

		Лог.Отладка(Команда.ПолучитьВывод());
	КонецЕсли;
	
КонецПроцедуры

Процедура ДобавитьКаталогBinВPath(Знач ПутьККаталогуBin)
	
	Лог.Отладка("Добавляю каталог %1 в PATH", ПутьККаталогуBin);
	
	ПеременнаяPATH = ПолучитьПеременнуюСреды("PATH", РасположениеПеременнойСреды.Пользователь);
	Если ЭтоWindows Тогда
		ИскомоеЗначение = "%OVM_OSCRIPTBIN%";
	Иначе
		ПутьКаталогуHOME = ПолучитьПеременнуюСреды("HOME");
		Если НЕ ПустаяСтрока(ПутьКаталогуHOME) Тогда
			ПутьККаталогуBin = СтрЗаменить(ПутьККаталогуBin, ПутьКаталогуHOME, "$HOME");
		КонецЕсли;
		ИскомоеЗначение = ПутьККаталогуBin;
	КонецЕсли;

	Если СтрНайти(ПеременнаяPATH, ИскомоеЗначение) <> 0 Тогда
		Лог.Отладка("PATH уже содержит путь к каталогу");
		Возврат;
	КонецЕсли;
	
	Если ЭтоWindows Тогда
		Лог.Отладка("Установка переменных среды на уровне пользователя");
		УстановитьПеременнуюСреды("OVM_OSCRIPTBIN", ПутьККаталогуBin, РасположениеПеременнойСреды.Пользователь);
		УстановитьПеременнуюСреды("PATH", "%OVM_OSCRIPTBIN%;" + ПеременнаяPATH, РасположениеПеременнойСреды.Пользователь);
	Иначе
		Лог.Отладка("Добавление каталога в PATH для shell");
		ТекстФайлаПрофиля = "export PATH=""" + ПутьККаталогуBin + ":$PATH""
		|export OSCRIPTBIN=""" + ПутьККаталогуBin + """";

		ПутьКФайлу = ОбъединитьПути(
			СистемнаяИнформация.ПолучитьПутьПапки(СпециальнаяПапка.ПрофильПользователя),
			".profile"
		);
		
		ДобавитьТекстВНовыйИлиИмеющийсяФайл(ТекстФайлаПрофиля, ПутьКФайлу);

		ПутьКФайлу = ОбъединитьПути(
			СистемнаяИнформация.ПолучитьПутьПапки(СпециальнаяПапка.ПрофильПользователя),
			".bashrc"
		);

		ДобавитьТекстВНовыйИлиИмеющийсяФайл(ТекстФайлаПрофиля, ПутьКФайлу);
	КонецЕсли;

КонецПроцедуры

Процедура ДобавитьТекстВНовыйИлиИмеющийсяФайл(Знач ДобавляемыйТекст, Знач ПутьКФайлу)
	
	Лог.Отладка(
		"Добавление текста в файл.
		|Текст:
		|%1
		|Файл:
		|%2",
		ДобавляемыйТекст,
		ПутьКФайлу
	);

	Если НЕ ФС.ФайлСуществует(ПутьКФайлу) Тогда
		Лог.Отладка("Файл не существует, создаю новый");

		Файл = Новый Файл(ПутьКФайлу);
		ФС.ОбеспечитьКаталог(Файл.Путь);
		
		ЗаписьТекста = Новый ЗаписьТекста(ПутьКФайлу, КодировкаТекста.UTF8NoBOM);
		ЗаписьТекста.Записать("");
		ЗаписьТекста.Закрыть();
	КонецЕсли;

	ЧтениеТекста = Новый ЧтениеТекста(ПутьКФайлу);
	НайденныйДобавляемыйТекст = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	Если СтрНайти(НайденныйДобавляемыйТекст, ДобавляемыйТекст) <> 0 Тогда
		Лог.Отладка("Файл уже содержит добавляемый текст");
		Возврат;
	КонецЕсли;
	
	ЗаписьТекста = Новый ЗаписьТекста();
	ЗаписьТекста.Открыть(ПутьКФайлу, КодировкаТекста.UTF8NoBOM, , Истина);
	
	ЗаписьТекста.ЗаписатьСтроку(ДобавляемыйТекст);
	ЗаписьТекста.Закрыть();
	
	Лог.Отладка("Текст добавлен в файл");
	
КонецПроцедуры

Процедура ПроверитьНаличиеИспользуемойВерсии(Знач ИспользуемаяВерсия, Знач ВыполнятьУстановкуПриНеобходимости)
	
	Если ВерсииOneScript.ВерсияУстановлена(ИспользуемаяВерсия) Тогда
		Возврат;
	КонецЕсли;
	
	Если ВыполнятьУстановкуПриНеобходимости Тогда
		УстановщикOneScript = Новый УстановщикOneScript();
		УстановщикOneScript.УстановитьOneScript(ИспользуемаяВерсия);
	Иначе
		ВызватьИсключение СтрШаблон("Не обнаружена требуемая версия <%1>", ИспользуемаяВерсия);
	КонецЕсли;
	
КонецПроцедуры

СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;
Лог = ПараметрыOVM.ПолучитьЛог();
