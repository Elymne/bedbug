/// Catégorie de la page de choix d'icône, dont le titre est traduit à l'affichage.
enum KaomojiCategory {
  /// Joie, bonne humeur.
  joy,

  /// Amour, tendresse.
  love,

  /// Gêne, timidité.
  shy,

  /// Tristesse, larmes.
  sad,

  /// Colère, agacement.
  angry,

  /// Peur, panique.
  scared,

  /// Surprise, stupeur.
  surprised,

  /// Indifférence, flemme, malice.
  meh,

  /// Salutations.
  greeting,

  /// Câlins.
  hug,

  /// Sommeil.
  sleepy,

  /// Victoire, motivation.
  victory,

  /// Danse, fête, musique.
  dance,

  /// Tables renversées.
  tableFlip,

  /// Chats.
  cat,

  /// Ours.
  bear,

  /// Autres animaux.
  animal,
}

/// Kaomojis proposés sur la page de choix d'icône, par catégorie.
///
/// Liste choisie à la main plutôt qu'importée : les bases trouvables en ligne
/// comptent des milliers d'entrées redondantes, et beaucoup utilisent des
/// caractères absents des polices Android (ils s'afficheraient en carrés
/// vides). Ici, chaque entrée tient dans la limite de longueur de l'icône et
/// n'utilise que des caractères courants. Le tout pèse quelques Ko.
const Map<KaomojiCategory, List<String>> kaomojiCatalog = {
  KaomojiCategory.joy: [
    '( ノ ^o^)ノ',
    '(◕‿◕)',
    '(＾▽＾)',
    '(✿◠‿◠)',
    '(≧▽≦)',
    'ヽ(•‿•)ノ',
    '(*^‿^*)',
    '(｡◕‿◕｡)',
    '٩(◕‿◕)۶',
    '(ﾉ◕ヮ◕)ﾉ',
    '(☆▽☆)',
    '＼(^o^)／',
  ],
  KaomojiCategory.love: [
    '(♥‿♥)',
    '(´∀｀)♡',
    '(≧◡≦) ♡',
    '(｡♥‿♥｡)',
    '(◍•ᴗ•◍)❤',
    '( ˘ ³˘)♥',
    '(*˘︶˘*)',
    '(灬º‿º灬)♡',
    '♡(｡- ω -)',
    '(づ￣ ³￣)づ',
  ],
  KaomojiCategory.shy: ['(⁄ ⁄•⁄ω⁄•⁄ ⁄)', '(*/ω＼*)', '(〃▽〃)', '(⌒_⌒;)', '(〃∀〃)', '(*ﾉωﾉ)', '(//▽//)', '(-_-;)'],
  KaomojiCategory.sad: ['(╥﹏╥)', '(ಥ﹏ಥ)', '(T_T)', '(;﹏;)', '(ノ_<。)', '(´；ω；`)', '(｡•́︿•̀｡)', '( ´•︵•` )'],
  KaomojiCategory.angry: ['(╬ Ò﹏Ó)', '(ง •̀_•́)ง', '(눈_눈)', '(ಠ_ಠ)', 'ヽ(`Д´)ﾉ', '(＃`Д´)', '(ノಠ益ಠ)ノ', '(¬_¬")'],
  KaomojiCategory.scared: ['(ﾉﾟ0ﾟ)ﾉ~', 'ヽ(°〇°)ﾉ', '(⊙_⊙;)', 'Σ(°ロ°)', '(・_・;)', '(ಡ_ಡ)'],
  KaomojiCategory.surprised: ['(°o°)', '(⊙ω⊙)', 'Σ(O_O)', '(◎_◎;)', '(O.O)', 'w(°ｏ°)w', '(ʘ‿ʘ)', '(・o・)'],
  KaomojiCategory.meh: [r'¯\_(ツ)_/¯', '( ͡° ͜ʖ ͡°)', '(¬‿¬)', '(￣～￣)', '(-_-)', '(︶︹︶)', '┐(￣ヘ￣)┌', '(￢_￢)', '(눈‸눈)'],
  KaomojiCategory.greeting: ['(・ω・)ノ', '(^-^*)/', 'ヾ(＾∇＾)', '(￣▽￣)ノ', '(*・ω・)ﾉ', '(＾０＾)ノ', '(o´ω`o)ﾉ'],
  KaomojiCategory.hug: ['(づ｡◕‿‿◕｡)づ', '(っ´▽`)っ', '⊂(・▽・⊂)', '(つ≧▽≦)つ', '(⊃｡•́‿•̀｡)⊃', '(づ ◕‿◕ )づ'],
  KaomojiCategory.sleepy: ['(－_－) zzZ', '(∪｡∪)｡｡｡zzZ', '(ᴗ˳ᴗ)', '(￣o￣) zzZ', '(-.-)Zzz'],
  KaomojiCategory.victory: ['(•̀ᴗ•́)و', 'ᕦ(ò_óˇ)ᕤ', 'ᕙ(⇀‸↼‶)ᕗ', '٩(ˊᗜˋ*)و', '(๑•̀ㅂ•́)و✧', r'\(^o^)/', '(ﾉ´ヮ`)ﾉ*:･ﾟ'],
  KaomojiCategory.dance: ['♪(┌・。・)┌', '└(＾＾)┐', '┌(＾＾)┘', 'ヾ(⌐■_■)ノ♪', '(~˘▾˘)~', '~(˘▾˘~)', '♪～(￣ε￣)'],
  KaomojiCategory.tableFlip: ['(╯°□°)╯︵ ┻━┻', '(ノಠ益ಠ)ノ彡┻━┻', '(┛ಠ_ಠ)┛彡┻━┻', '┬─┬ノ( º _ ºノ)'],
  KaomojiCategory.cat: ['(=^･ω･^=)', '(=^‥^=)', 'ฅ^•ﻌ•^ฅ', '(=ↀωↀ=)', r'/ᐠ｡ꞈ｡ᐟ\', 'ᓚᘏᗢ'],
  KaomojiCategory.bear: ['ʕ•ᴥ•ʔ', 'ʕ ᵔᴥᵔ ʔ', 'ʕ •`ᴥ•´ʔ', 'ʕノ•ᴥ•ʔノ', 'ʕ´•ᴥ•`ʔ', '(ᵔᴥᵔ)'],
  KaomojiCategory.animal: ['∪･ω･∪', 'U^ｪ^U', '(・ᴥ・)', r'(\_/)', r'/(≧ x ≦)\', '(・θ・)', '>°)))彡', '<コ:彡'],
};
