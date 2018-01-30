Перем ВерсииOneScript;
Перем Лог;

Процедура ОписаниеКоманды(КомандаПриложения) Экспорт
	
	КомандаПриложения.Опция("force f", Ложь, "Удалять даже текущую используемую версию");
	КомандаПриложения.Опция("all a", Ложь, "Удаление всех установленных версий OneScript");
	КомандаПриложения.Аргумент("VERSION", , "Удаляемая версия OneScript (возвможна передача нескольких значений). Допустимо использовать трехномерные версии (1.0.17, 1.0.18), stable, dev")
		.ТМассивСтрок();
		
	КомандаПриложения.Спек = "[--force] [--all] [VERSION...]";
КонецПроцедуры

Процедура ВыполнитьКоманду(Знач КомандаПриложения) Экспорт
	
	МассивВерсийКУдалению = КомандаПриложения.ЗначениеАргумента("VERSION");
	УдалятьТекущуюВерсию = КомандаПриложения.ЗначениеОпции("force");
	УдалятьВсеВерсии = КомандаПриложения.ЗначениеОпции("all");

	ДеинсталляторOneScript = Новый ДеинсталляторOneScript();
	
	Если УдалятьВсеВерсии Тогда
		ДеинсталляторOneScript.УдалитьВсеВерсииOneScript();
	Иначе
			
		Для Каждого ВерсияКУдалению Из МассивВерсийКУдалению Цикл
			Если ВерсииOneScript.ЭтоТекущаяВерсия(ВерсияКУдалению) И НЕ УдалятьТекущуюВерсию Тогда
				Лог.Информация("Версия <%1> не удалена, т.к. является текущей.", ВерсияКУдалению);
				Продолжить;
			КонецЕсли;
			ДеинсталляторOneScript.УдалитьOneScript(ВерсияКУдалению);
		КонецЦикла;
		
	КонецЕсли;
		
КонецПроцедуры

ВерсииOneScript = Новый ВерсииOneScript();
Лог = ПараметрыOVM.ПолучитьЛог();
