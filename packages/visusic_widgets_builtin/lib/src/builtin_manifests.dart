// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

/// Versioned built-in widget manifests loaded through the same validator used
/// for community templates.
const String builtinManifestsJson = r'''
{"widgets":[
  {
    "schemaVersion":1,"id":"builtin.rectangle","version":"1.0.0",
    "name":{"en":"Rectangle","ru":"Прямоугольник"},"author":"VisuSic","category":"basic",
    "tags":["shape","color","background"],"requires":{"audio":false,"lyrics":false},
    "anchor":{"default":"center","resizable":true,"aspectLock":false,"width":480,"height":320},
    "params":[
      {"id":"fill","type":"gradient","label":{"en":"Fill","ru":"Заливка"},"default":["#7C4DFF","#3DDC97"],"primary":true},
      {"id":"cornerRadius","type":"float","label":{"en":"Corners","ru":"Скругление"},"min":0,"max":500,"default":32,"unit":"px","primary":true},
      {"id":"opacity","type":"float","label":{"en":"Opacity","ru":"Непрозрачность"},"min":0,"max":1,"default":1,"primary":true},
      {"id":"borderWidth","type":"float","label":{"en":"Border","ru":"Контур"},"min":0,"max":40,"default":0,"unit":"px"},
      {"id":"borderColor","type":"color","label":{"en":"Border color","ru":"Цвет контура"},"default":"#FFFFFF"}
    ],
    "bindings":[{"id":"bass","feature":"band.bass","attack":20,"release":180}],
    "expressions":{},"render":{"type":"native","id":"rectangle"}
  },
  {
    "schemaVersion":1,"id":"builtin.text","version":"1.0.0",
    "name":{"en":"Text","ru":"Текст"},"author":"VisuSic","category":"text",
    "tags":["title","static","typography"],"requires":{"audio":false,"lyrics":false},
    "anchor":{"default":"center","resizable":true,"aspectLock":false,"width":900,"height":180},
    "params":[
      {"id":"text","type":"multiline","label":{"en":"Text","ru":"Текст"},"default":"Your text","primary":true},
      {"id":"size","type":"float","label":{"en":"Size","ru":"Размер"},"min":12,"max":240,"default":72,"unit":"px","primary":true},
      {"id":"color","type":"color","label":{"en":"Color","ru":"Цвет"},"default":"#FFFFFF","primary":true},
      {"id":"weight","type":"enum","label":{"en":"Weight","ru":"Начертание"},"options":["regular","medium","bold"],"default":"medium"},
      {"id":"align","type":"enum","label":{"en":"Alignment","ru":"Выравнивание"},"options":["left","center","right"],"default":"center"},
      {"id":"reveal","type":"enum","label":{"en":"Reveal","ru":"Появление"},"options":["none","perLetter","typewriter","fade"],"default":"none"},
      {"id":"letterSpacing","type":"float","label":{"en":"Letter spacing","ru":"Межбуквенный"},"min":-4,"max":30,"default":0,"unit":"px"}
    ],
    "bindings":[],"expressions":{},"render":{"type":"native","id":"text"}
  },
  {
    "schemaVersion":1,"id":"builtin.title","version":"1.0.0",
    "name":{"en":"Kinetic Title","ru":"Анимированный заголовок"},"author":"VisuSic","category":"text",
    "tags":["title","reveal","kinetic"],"requires":{"audio":false,"lyrics":false},
    "anchor":{"default":"center","resizable":true,"aspectLock":false,"width":1000,"height":240},
    "params":[
      {"id":"text","type":"multiline","label":{"en":"Title","ru":"Заголовок"},"default":"YOUR TITLE","primary":true},
      {"id":"size","type":"float","label":{"en":"Size","ru":"Размер"},"min":20,"max":280,"default":112,"unit":"px","primary":true},
      {"id":"fill","type":"gradient","label":{"en":"Fill","ru":"Заливка"},"default":["#FFFFFF","#B69CFF"],"primary":true},
      {"id":"weight","type":"enum","label":{"en":"Weight","ru":"Начертание"},"options":["regular","medium","bold"],"default":"bold"},
      {"id":"align","type":"enum","label":{"en":"Alignment","ru":"Выравнивание"},"options":["left","center","right"],"default":"center"},
      {"id":"reveal","type":"enum","label":{"en":"Animation","ru":"Анимация"},"options":["perLetter","slide","typewriter","fade"],"default":"perLetter"},
      {"id":"letterSpacing","type":"float","label":{"en":"Letter spacing","ru":"Межбуквенный"},"min":-4,"max":30,"default":2,"unit":"px"}
    ],
    "bindings":[],"expressions":{},"render":{"type":"native","id":"title"}
  },
  {
    "schemaVersion":1,"id":"builtin.image","version":"1.0.0",
    "name":{"en":"Image","ru":"Изображение"},"author":"VisuSic","category":"basic",
    "tags":["image","photo","asset"],"requires":{"audio":false,"lyrics":false},
    "anchor":{"default":"center","resizable":true,"aspectLock":false,"width":640,"height":480},
    "params":[
      {"id":"asset","type":"image","label":{"en":"Image","ru":"Изображение"},"default":"","primary":true},
      {"id":"fit","type":"enum","label":{"en":"Fit","ru":"Заполнение"},"options":["cover","contain"],"default":"cover","primary":true},
      {"id":"opacity","type":"float","label":{"en":"Opacity","ru":"Непрозрачность"},"min":0,"max":1,"default":1,"primary":true},
      {"id":"cornerRadius","type":"float","label":{"en":"Corners","ru":"Скругление"},"min":0,"max":500,"default":0,"unit":"px"}
    ],
    "bindings":[],"expressions":{},"render":{"type":"native","id":"image"}
  },
  {
    "schemaVersion":1,"id":"builtin.barSpectrum","version":"1.0.0",
    "name":{"en":"Bar Spectrum","ru":"Спектр-столбики"},"author":"VisuSic","category":"audio",
    "tags":["spectrum","bars","demo","new"],"requires":{"audio":true,"lyrics":false},
    "anchor":{"default":"bottom-center","resizable":true,"aspectLock":false,"width":1200,"height":320},
    "params":[
      {"id":"barCount","type":"int","label":{"en":"Bars","ru":"Столбиков"},"min":8,"max":96,"default":48,"primary":true},
      {"id":"colors","type":"gradient","label":{"en":"Colors","ru":"Цвета"},"default":["#7C4DFF","#3DDC97"],"primary":true},
      {"id":"gap","type":"float","label":{"en":"Gap","ru":"Промежуток"},"min":0,"max":40,"default":4,"unit":"px","primary":true},
      {"id":"minHeight","type":"float","label":{"en":"Minimum height","ru":"Мин. высота"},"min":0,"max":40,"default":4,"unit":"px"},
      {"id":"cornerRadius","type":"float","label":{"en":"Corners","ru":"Скругление"},"min":0,"max":40,"default":4,"unit":"px"},
      {"id":"mirror","type":"bool","label":{"en":"Mirror","ru":"Зеркальный"},"default":false},
      {"id":"peaks","type":"bool","label":{"en":"Peak caps","ru":"Пики"},"default":true},
      {"id":"glow","type":"float","label":{"en":"Glow","ru":"Свечение"},"min":0,"max":24,"default":8,"unit":"px"}
    ],
    "bindings":[{"id":"kick","feature":"beat.isBeat","release":180,"curve":"expo"}],
    "expressions":{"glowBoost":"bind.kick * params.glow"},"render":{"type":"native","id":"barSpectrum"}
  },
  {
    "schemaVersion":1,"id":"builtin.meshGradient","version":"1.0.0",
    "name":{"en":"Mesh Gradient","ru":"Живой градиент"},"author":"VisuSic","category":"background",
    "tags":["gradient","background","new"],"requires":{"audio":true,"lyrics":false},
    "anchor":{"default":"fill","resizable":true,"aspectLock":false,"width":1920,"height":1080},
    "params":[
      {"id":"colors","type":"gradient","label":{"en":"Palette","ru":"Палитра"},"default":["#101014","#7C4DFF","#3DDC97","#FF7A90"],"primary":true},
      {"id":"speed","type":"float","label":{"en":"Speed","ru":"Скорость"},"min":0,"max":2,"default":0.25,"primary":true},
      {"id":"pulse","type":"float","label":{"en":"Beat pulse","ru":"Пульс на битах"},"min":0,"max":0.4,"default":0.08,"primary":true}
    ],
    "bindings":[{"id":"bass","feature":"band.bass","attack":20,"release":220}],
    "expressions":{"scale":"1 + bind.bass * params.pulse"},"render":{"type":"native","id":"meshGradient"}
  },
  {
    "schemaVersion":1,"id":"builtin.particles","version":"1.0.0",
    "name":{"en":"Particles Field","ru":"Поле частиц"},"author":"VisuSic","category":"background",
    "tags":["particles","snow","dust","new"],"requires":{"audio":true,"lyrics":false},
    "anchor":{"default":"fill","resizable":true,"aspectLock":false,"width":1920,"height":1080},
    "params":[
      {"id":"count","type":"int","label":{"en":"Count","ru":"Количество"},"min":10,"max":300,"default":140,"primary":true},
      {"id":"speed","type":"float","label":{"en":"Speed","ru":"Скорость"},"min":0,"max":3,"default":0.4,"primary":true},
      {"id":"mode","type":"enum","label":{"en":"Style","ru":"Стиль"},"options":["dust","snow","rain","petals","sparks"],"default":"dust","primary":true},
      {"id":"size","type":"float","label":{"en":"Size","ru":"Размер"},"min":1,"max":30,"default":4,"unit":"px"},
      {"id":"color","type":"color","label":{"en":"Color","ru":"Цвет"},"default":"#FFFFFF"},
      {"id":"opacity","type":"float","label":{"en":"Opacity","ru":"Непрозрачность"},"min":0,"max":1,"default":0.65},
      {"id":"beatBoost","type":"float","label":{"en":"Beat speed","ru":"Ускорение на битах"},"min":0,"max":2,"default":0.5}
    ],
    "bindings":[{"id":"energy","feature":"energy.short","attack":30,"release":200}],
    "expressions":{"speedBoost":"1 + bind.energy * params.beatBoost"},"render":{"type":"native","id":"particles"}
  },
  {
    "schemaVersion":1,"id":"builtin.albumArt","version":"1.0.0",
    "name":{"en":"Album Art","ru":"Обложка"},"author":"VisuSic","category":"audio",
    "tags":["cover","album","vinyl","new"],"requires":{"audio":true,"lyrics":false},
    "anchor":{"default":"center","resizable":true,"aspectLock":true,"width":600,"height":600},
    "params":[
      {"id":"asset","type":"image","label":{"en":"Artwork","ru":"Обложка"},"default":""},
      {"id":"shape","type":"enum","label":{"en":"Shape","ru":"Форма"},"options":["vinyl","square","circle"],"default":"vinyl","primary":true},
      {"id":"kenBurns","type":"float","label":{"en":"Slow zoom","ru":"Медленный зум"},"min":0,"max":0.3,"default":0.08,"primary":true},
      {"id":"pulse","type":"float","label":{"en":"Beat pulse","ru":"Пульс на битах"},"min":0,"max":0.3,"default":0.06,"primary":true},
      {"id":"shadow","type":"float","label":{"en":"Shadow","ru":"Тень"},"min":0,"max":1,"default":0.35}
    ],
    "bindings":[{"id":"kick","feature":"beat.isBeat","release":180,"curve":"expo"}],
    "expressions":{"scale":"1 + bind.kick * params.pulse"},"render":{"type":"native","id":"albumArt"}
  },
  {
    "schemaVersion":1,"id":"builtin.progress","version":"1.0.0",
    "name":{"en":"Progress Bar","ru":"Прогресс трека"},"author":"VisuSic","category":"meta",
    "tags":["progress","time","new"],"requires":{"audio":false,"lyrics":false},
    "anchor":{"default":"bottom-center","resizable":true,"aspectLock":false,"width":1400,"height":100},
    "params":[
      {"id":"color","type":"color","label":{"en":"Color","ru":"Цвет"},"default":"#B69CFF","primary":true},
      {"id":"thickness","type":"float","label":{"en":"Thickness","ru":"Толщина"},"min":2,"max":40,"default":8,"unit":"px","primary":true},
      {"id":"showTime","type":"bool","label":{"en":"Show time","ru":"Показывать время"},"default":true,"primary":true},
      {"id":"backgroundColor","type":"color","label":{"en":"Track color","ru":"Цвет дорожки"},"default":"#40FFFFFF"}
    ],
    "bindings":[],"expressions":{},"render":{"type":"native","id":"progress"}
  },
  {
    "schemaVersion":1,"id":"builtin.scrim","version":"1.0.0",
    "name":{"en":"Readability Scrim","ru":"Подложка для читаемости"},"author":"VisuSic","category":"meta",
    "tags":["scrim","contrast","text","new"],"requires":{"audio":false,"lyrics":false},
    "anchor":{"default":"bottom-center","resizable":true,"aspectLock":false,"width":1400,"height":500},
    "params":[
      {"id":"opacity","type":"float","label":{"en":"Opacity","ru":"Непрозрачность"},"min":0,"max":1,"default":0.5,"primary":true},
      {"id":"placement","type":"enum","label":{"en":"Placement","ru":"Расположение"},"options":["bottom","top","center","full"],"default":"bottom","primary":true},
      {"id":"cornerRadius","type":"float","label":{"en":"Corners","ru":"Скругление"},"min":0,"max":100,"default":24,"unit":"px","primary":true},
      {"id":"color","type":"color","label":{"en":"Color","ru":"Цвет"},"default":"#000000"}
    ],
    "bindings":[],"expressions":{},"render":{"type":"native","id":"scrim"}
  },
  {
    "schemaVersion":1,"id":"builtin.karaoke","version":"1.0.0",
    "name":{"en":"Karaoke Lyrics","ru":"Караоке-текст"},"author":"VisuSic","category":"text",
    "tags":["lyrics","karaoke","sync","new"],"requires":{"audio":false,"lyrics":true},
    "anchor":{"default":"bottom-center","resizable":true,"aspectLock":false,"width":1400,"height":260},
    "params":[
      {"id":"size","type":"float","label":{"en":"Size","ru":"Размер"},"min":24,"max":160,"default":64,"unit":"px","primary":true},
      {"id":"colors","type":"gradient","label":{"en":"Colors","ru":"Цвета"},"default":["#FFFFFF","#B69CFF"],"primary":true},
      {"id":"mode","type":"enum","label":{"en":"Highlight","ru":"Подсветка"},"options":["wipe","bounce","perLetter","glow"],"default":"wipe","primary":true},
      {"id":"align","type":"enum","label":{"en":"Alignment","ru":"Выравнивание"},"options":["left","center","right"],"default":"center"},
      {"id":"nextLines","type":"int","label":{"en":"Next lines","ru":"Следующие строки"},"min":0,"max":3,"default":1},
      {"id":"inactiveOpacity","type":"float","label":{"en":"Inactive opacity","ru":"Прозрачность неактивных"},"min":0,"max":1,"default":0.4},
      {"id":"pulse","type":"float","label":{"en":"Beat pulse","ru":"Пульс на битах"},"min":0,"max":0.4,"default":0.08}
    ],
    "bindings":[{"id":"kick","feature":"beat.isBeat","release":180,"curve":"expo"}],
    "expressions":{"scale":"1 + bind.kick * params.pulse"},"render":{"type":"native","id":"karaoke"}
  },
  {
    "schemaVersion":1,"id":"builtin.rollingLyrics","version":"1.0.0",
    "name":{"en":"Rolling Lyrics","ru":"Бегущий текст"},"author":"VisuSic","category":"text",
    "tags":["lyrics","rolling","new"],"requires":{"audio":false,"lyrics":true},
    "anchor":{"default":"center","resizable":true,"aspectLock":false,"width":900,"height":320},
    "params":[
      {"id":"size","type":"float","label":{"en":"Size","ru":"Размер"},"min":18,"max":96,"default":36,"unit":"px","primary":true},
      {"id":"color","type":"color","label":{"en":"Color","ru":"Цвет"},"default":"#FFFFFF","primary":true},
      {"id":"activeColor","type":"color","label":{"en":"Active color","ru":"Цвет активной"},"default":"#B69CFF","primary":true},
      {"id":"lines","type":"int","label":{"en":"Visible lines","ru":"Видимых строк"},"min":3,"max":7,"default":5}
    ],
    "bindings":[],"expressions":{},"render":{"type":"native","id":"rollingLyrics"}
  }
]}
''';
