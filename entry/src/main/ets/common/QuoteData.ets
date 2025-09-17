// 名言数据管理
export interface Quote {
  text: string;
  author?: string;
  category: string;
  season?: string;
  weather?: string;
  source?: string;
}

export enum QuoteSource {
  SHIJING = 'shijing',
  MAOZEDONG = 'maozedong'
}

export class QuoteData {
  private static shijingQuotes: Quote[] = [
    // 爱情与情感
    { text: "关关雎鸠，在河之洲。窈窕淑女，君子好逑。", category: "爱情", source: "《诗经·周南·关雎》" },
    { text: "求之不得，寤寐思服。悠哉悠哉，辗转反侧。", category: "爱情", source: "《诗经·周南·关雎》" },
    { text: "桃之夭夭，灼灼其华。之子于归，宜其室家。", category: "爱情", season: "春", source: "《诗经·周南·桃夭》" },
    { text: "蒹葭苍苍，白露为霜。所谓伊人，在水一方。", category: "思念", season: "秋", weather: "cold", source: "《诗经·秦风·蒹葭》" },
    { text: "溯洄从之，道阻且长。溯游从之，宛在水中央。", category: "思念", source: "《诗经·秦风·蒹葭》" },
    { text: "子衿青青，悠悠我心。纵我不往，子宁不嗣音。", category: "思念", source: "《诗经·郑风·子衿》" },
    { text: "一日不见，如三秋兮。", category: "思念", source: "《诗经·王风·采葛》" },
    { text: "死生契阔，与子成说。执子之手，与子偕老。", category: "爱情", source: "《诗经·邶风·击鼓》" },
    { text: "愿言思伯，甘心首疾。", category: "爱情", source: "《诗经·卫风·伯兮》" },
    { text: "有美一人，清扬婉兮。邂逅相遇，适我愿兮。", category: "爱情", source: "《诗经·郑风·野有蔓草》" },

    // 自然与季节
    { text: "春日迟迟，卉木萋萋。仓庚喈喈，采蘩祁祁。", category: "自然", season: "春", source: "《诗经·豳风·七月》" },
    { text: "四月维夏，六月徂暑。", category: "自然", season: "夏", source: "《诗经·小雅·四月》" },
    { text: "秋日凄凄，百卉具腓。乱离瘼矣，爰其适归。", category: "自然", season: "秋", source: "《诗经·小雅·四月》" },
    { text: "雨雪霏霏，见晛曰消。莫肯下遗，式救斯民。", category: "自然", season: "冬", weather: "snowy", source: "《诗经·小雅·雨无正》" },
    { text: "昔我往矣，杨柳依依。今我来思，雨雪霏霏。", category: "离别", season: "冬", weather: "snowy", source: "《诗经·小雅·采薇》" },
    { text: "野有蔓草，零露溥兮。有美一人，婉如清扬。", category: "自然", weather: "sunny", source: "《诗经·郑风·野有蔓草》" },
    { text: "彼采萧兮，一日不见，如三秋兮。", category: "思念", season: "秋", source: "《诗经·王风·采葛》" },
    { text: "七月流火，九月授衣。", category: "时节", season: "秋", source: "《诗经·豳风·七月》" },
    { text: "青青子衿，悠悠我心。", category: "思念", source: "《诗经·郑风·子衿》" },
    { text: "东门之杨，其叶牂牂。昏以为期，明星煌煌。", category: "约会", source: "《诗经·陈风·东门之杨》" },

    // 离别与思乡
    { text: "行道迟迟，载渴载饥。我心伤悲，莫知我哀。", category: "离别", source: "《诗经·小雅·采薇》" },
    { text: "维桑与梓，必恭敬止。靡瞻匪父，靡依匪母。", category: "思乡", source: "《诗经·小雅·小弁》" },
    { text: "式微式微，胡不归。微君之故，胡为乎中露。", category: "思乡", source: "《诗经·邶风·式微》" },
    { text: "女曰鸡鸣，士曰昧旦。子兴视夜，明星有烂。", category: "生活", source: "《诗经·郑风·女曰鸡鸣》" },
    { text: "投我以木瓜，报之以琼琚。匪报也，永以为好也。", category: "友情", source: "《诗经·卫风·木瓜》" },
    { text: "投我以木桃，报之以琼瑶。匪报也，永以为好也。", category: "友情", source: "《诗经·卫风·木瓜》" },
    { text: "绸缪束薪，三星在天。今夕何夕，见此良人。", category: "爱情", source: "《诗经·唐风·绸缪》" },
    { text: "河水洋洋，北流活活。施罛濊濊，鳣鲔发发。", category: "自然", source: "《诗经·卫风·河广》" },
    { text: "谁谓河广，一苇杭之。谁谓宋远，跂予望之。", category: "思念", source: "《诗经·卫风·河广》" },
    { text: "静女其姝，俟我于城隅。爱而不见，搔首踟蹰。", category: "爱情", source: "《诗经·邶风·静女》" },

    // 品德与修养
    { text: "如切如磋，如琢如磨。", category: "修养", source: "《诗经·卫风·淇奥》" },
    { text: "瞻彼淇奥，绿竹猗猗。有匪君子，如切如磋。", category: "修养", source: "《诗经·卫风·淇奥》" },
    { text: "温温恭人，如集于木。惴惴小心，如临于谷。", category: "修养", source: "《诗经·小雅·小旻》" },
    { text: "战战兢兢，如临深渊，如履薄冰。", category: "谨慎", source: "《诗经·小雅·小旻》" },
    { text: "他山之石，可以攻玉。", category: "学习", source: "《诗经·小雅·鹤鸣》" },
    { text: "鹤鸣于九皋，声闻于野。鱼潜在渊，或在于渚。", category: "哲理", source: "《诗经·小雅·鹤鸣》" },
    { text: "投我以桃，报之以李。", category: "礼仪", source: "《诗经·大雅·抑》" },
    { text: "诲尔谆谆，听我藐藐。", category: "教育", source: "《诗经·大雅·抑》" },
    { text: "匪风发兮，匪车偈兮。顾瞻周道，中心怛兮。", category: "忧国", source: "《诗经·邶风·匪风》" },
    { text: "言者无罪，闻者足戒。", category: "批评", source: "《诗经·大序》" },

    // 劳动与生活
    { text: "十月蟋蟀入我床下。穹窒熏鼠，塞向墐户。", category: "生活", season: "秋", source: "《诗经·豳风·七月》" },
    { text: "二之日凿冰冲冲，三之日纳于凌阴。", category: "劳动", season: "冬", source: "《诗经·豳风·七月》" },
    { text: "春日载阳，有鸣仓庚。女执懿筐，遵彼微行。", category: "劳动", season: "春", source: "《诗经·豳风·七月》" },
    { text: "采采卷耳，不盈顷筐。嗟我怀人，寘彼周行。", category: "劳动", source: "《诗经·周南·卷耳》" },
    { text: "参差荇菜，左右流之。窈窕淑女，寤寐求之。", category: "劳动", source: "《诗经·周南·关雎》" },
    { text: "采采芣苢，薄言采之。采采芣苢，薄言有之。", category: "劳动", source: "《诗经·周南·芣苢》" },
    { text: "南有乔木，不可休思。汉有游女，不可求思。", category: "哲理", source: "《诗经·周南·汝坟》" },
    { text: "无衣无褐，何以卒岁。", category: "生活", season: "冬", source: "《诗经·豳风·七月》" },
    { text: "女心伤悲，殆及公子同归。", category: "婚姻", source: "《诗经·召南·摽有梅》" },
    { text: "摽有梅，其实七兮。求我庶士，迨其吉兮。", category: "婚姻", source: "《诗经·召南·摽有梅》" },

    // 政治与社会
    { text: "民之秉彝，好是懿德。", category: "品德", source: "《诗经·大雅·烝民》" },
    { text: "天生烝民，有物有则。民之秉彝，好是懿德。", category: "品德", source: "《诗经·大雅·烝民》" },
    { text: "高山仰止，景行行止。", category: "敬仰", source: "《诗经·小雅·车舝》" },
    { text: "既明且哲，以保其身。", category: "智慧", source: "《诗经·大雅·烝民》" },
    { text: "靡不有初，鲜克有终。", category: "恒心", source: "《诗经·大雅·荡》" },
    { text: "多行不义必自毙。", category: "正义", source: "《诗经·小雅·巧言》" },
    { text: "维号斯言，有伦有脊。", category: "言行", source: "《诗经·大雅·假乐》" },
    { text: "乐只君子，万寿无疆。", category: "祝福", source: "《诗经·小雅·南山有台》" },
    { text: "如月之恒，如日之升。", category: "祝福", source: "《诗经·小雅·天保》" },
    { text: "如南山之寿，不骞不崩。", category: "祝福", source: "《诗经·小雅·天保》" },

    // 友谊与人际
    { text: "嘤其鸣矣，求其友声。", category: "友谊", source: "《诗经·小雅·伐木》" },
    { text: "既见君子，我心则喜。", category: "友谊", source: "《诗经·小雅·菁菁者莪》" },
    { text: "有匪君子，如金如锡，如圭如璧。", category: "品格", source: "《诗经·卫风·淇奥》" },
    { text: "巧言如簧，颜之厚矣。", category: "讽刺", source: "《诗经·小雅·巧言》" },
    { text: "他人有心，予忖度之。", category: "理解", source: "《诗经·小雅·巧言》" },
    { text: "知我者谓我心忧，不知我者谓我何求。", category: "理解", source: "《诗经·王风·黍离》" },
    { text: "彼黍离离，彼稷之苗。行迈靡靡，中心摇摇。", category: "感怀", source: "《诗经·王风·黍离》" },
    { text: "采葛采葛，首阳之巅。人之为言，苟亦无信。", category: "诚信", source: "《诗经·王风·采葛》" },
    { text: "终风且暴，顾我则笑。谑浪笑敖，中心是悼。", category: "情感", source: "《诗经·邶风·终风》" },
    { text: "邂逅相遇，与子偕臧。", category: "友谊", source: "《诗经·郑风·野有蔓草》" },

    // 感慨与哲理
    { text: "昔我往矣，杨柳依依。今我来思，雨雪霏霏。", category: "时光", season: "冬", weather: "snowy", source: "《诗经·小雅·采薇》" },
    { text: "人生如寄，多忧何为。", category: "人生", source: "《诗经·唐风·山有枢》" },
    { text: "山有木兮木有枝，心悦君兮君不知。", category: "暗恋", source: "《诗经·越人歌》" },
    { text: "皎皎白驹，食我场苗。縶之维之，以永今朝。", category: "惜时", source: "《诗经·小雅·白驹》" },
    { text: "所谓伊人，在水一方。", category: "思念", source: "《诗经·秦风·蒹葭》" },
    { text: "绸缪束楚，三星在户。今夕何夕，见此粲者。", category: "美好", source: "《诗经·唐风·绸缪》" },
    { text: "月出皎兮，佼人僚兮。舒窈纠兮，劳心悄兮。", category: "思念", source: "《诗经·陈风·月出》" },
    { text: "关关雎鸠，在河之洲。", category: "和谐", source: "《诗经·周南·关雎》" },
    { text: "风雨如晦，鸡鸣不已。既见君子，云胡不喜。", category: "坚持", weather: "rainy", source: "《诗经·郑风·风雨》" },
    { text: "青青子佩，悠悠我思。纵我不往，子宁不来。", category: "思念", source: "《诗经·郑风·子衿》" },

    // 自然景物
    { text: "呦呦鹿鸣，食野之苹。我有嘉宾，鼓瑟吹笙。", category: "宴客", source: "《诗经·小雅·鹿鸣》" },
    { text: "泽陂汇汇，禾役役。", category: "自然", source: "《诗经·陈风·泽陂》" },
    { text: "鱼在在藻，有颁其首。王在在镐，岂乐饮酒。", category: "自然", source: "《诗经·小雅·鱼藻》" },
    { text: "维南有箕，不可以簸扬。维北有斗，不可以挹酒浆。", category: "哲理", source: "《诗经·小雅·大东》" },
    { text: "硕鼠硕鼠，无食我黍。三岁贯女，莫我肯顾。", category: "愤懑", source: "《诗经·魏风·硕鼠》" },
    { text: "坎坎伐檀兮，置之河之干兮。河水清且涟猗。", category: "劳动", source: "《诗经·魏风·伐檀》" },
    { text: "不素餐兮！", category: "勤俭", source: "《诗经·魏风·伐檀》" },
    { text: "采采芣苢，薄言掇之。采采芣苢，薄言捋之。", category: "劳动", source: "《诗经·周南·芣苢》" },
    { text: "葛之覃兮，施于中谷，维叶萋萋。", category: "自然", source: "《诗经·周南·葛覃》" },
    { text: "螽斯羽，诜诜兮。宜尔子孙，振振兮。", category: "祝福", source: "《诗经·周南·螽斯》" },

    // 婚恋家庭
    { text: "桃之夭夭，灼灼其华。之子于归，宜其室家。", category: "婚姻", season: "春", source: "《诗经·周南·桃夭》" },
    { text: "宜其室家，宜其家人。", category: "家庭", source: "《诗经·周南·桃夭》" },
    { text: "父兮生我，母兮鞠我。抚我畜我，长我育我。", category: "感恩", source: "《诗经·小雅·蓼莪》" },
    { text: "欲报之德，昊天罔极。", category: "感恩", source: "《诗经·小雅·蓼莪》" },
    { text: "凯风自南，吹彼棘心。棘心夭夭，母氏劬劳。", category: "母爱", source: "《诗经·邶风·凯风》" },
    { text: "哀哀父母，生我劬劳。", category: "感恩", source: "《诗经·小雅·蓼莪》" },
    { text: "兄弟阋于墙，外御其务。", category: "兄弟", source: "《诗经·小雅·棠棣》" },
    { text: "常棣之华，鄂不韡韡。凡今之人，莫如兄弟。", category: "兄弟", source: "《诗经·小雅·棠棣》" },
    { text: "死生契阔，与子成说。", category: "承诺", source: "《诗经·邶风·击鼓》" },
    { text: "琴瑟在御，莫不静好。", category: "和谐", source: "《诗经·郑风·女曰鸡鸣》" }
  ];

  private static maozedongQuotes: Quote[] = [
    // 论持久战
    { text: "战争的伟力之最深厚的根源，存在于民众之中。", author: "毛泽东", category: "战争", source: "《论持久战》" },
    { text: "兵民是胜利之本。", author: "毛泽东", category: "战争", source: "《论持久战》" },
    { text: "武器是战争的重要的因素，但不是决定的因素，决定的因素是人不是物。", author: "毛泽东", category: "战争", source: "《论持久战》" },
    { text: "战略上要藐视敌人，战术上要重视敌人。", author: "毛泽东", category: "战略", source: "《论持久战》" },
    { text: "敌进我退，敌驻我扰，敌疲我打，敌退我追。", author: "毛泽东", category: "战略", source: "《中国革命战争的战略问题》" },
    { text: "打得赢就打，打不赢就走。", author: "毛泽东", category: "战略", source: "《论持久战》" },
    { text: "集中优势兵力，各个歼灭敌人。", author: "毛泽东", category: "战略", source: "《中国革命战争的战略问题》" },
    { text: "我们的战略是以一当十，我们的战术是以十当一。", author: "毛泽东", category: "战略", source: "《论持久战》" },
    { text: "保存自己，消灭敌人，这是战争的根本法则。", author: "毛泽东", category: "战争", source: "《中国革命战争的战略问题》" },
    { text: "一切反动派都是纸老虎。", author: "毛泽东", category: "斗争", source: "《和美国记者安娜·路易斯·斯特朗的谈话》" },

    // 实践论
    { text: "实践是检验真理的唯一标准。", author: "毛泽东", category: "真理", source: "《实践论》" },
    { text: "人的正确思想是从哪里来的？是从天上掉下来的吗？不是。是自己头脑里固有的吗？不是。人的正确思想，只能从社会实践中来。", author: "毛泽东", category: "认识", source: "《实践论》" },
    { text: "认识从实践始，经过实践得到了理论的认识，还须再回到实践去。", author: "毛泽东", category: "实践", source: "《实践论》" },
    { text: "通过实践而发现真理，又通过实践而证实真理和发展真理。", author: "毛泽东", category: "真理", source: "《实践论》" },
    { text: "感觉只解决现象问题，理论才解决本质问题。", author: "毛泽东", category: "认识", source: "《实践论》" },
    { text: "理论的基础是实践，又转过来为实践服务。", author: "毛泽东", category: "理论", source: "《实践论》" },
    { text: "人们的认识能力是无限的。", author: "毛泽东", category: "认识", source: "《实践论》" },
    { text: "马克思主义者认为，只有人们的社会实践，才是人们对于外界认识的真理性的标准。", author: "毛泽东", category: "真理", source: "《实践论》" },

    // 矛盾论
    { text: "矛盾是普遍的，绝对的，它存在于一切事物发展的全过程中。", author: "毛泽东", category: "矛盾", source: "《矛盾论》" },
    { text: "对立统一规律是宇宙的根本规律。", author: "毛泽东", category: "矛盾", source: "《矛盾论》" },
    { text: "一切过程的开始阶段，是简单的、感性的、片面的。", author: "毛泽东", category: "发展", source: "《矛盾论》" },
    { text: "主要的矛盾和非主要的矛盾、主要的矛盾方面和非主要的矛盾方面是可以互相转化的。", author: "毛泽东", category: "矛盾", source: "《矛盾论》" },
    { text: "具体地分析具体情况，这是马克思主义的最本质的东西，马克思主义的活的灵魂。", author: "毛泽东", category: "方法", source: "《矛盾论》" },
    { text: "在复杂的事物的发展过程中，有许多的矛盾存在，其中必有一种是主要的矛盾。", author: "毛泽东", category: "矛盾", source: "《矛盾论》" },
    { text: "质就是一事物区别于其他事物的内部规定性。", author: "毛泽东", category: "哲学", source: "《矛盾论》" },

    // 为人民服务思想
    { text: "为人民服务。", author: "毛泽东", category: "服务", source: "《为人民服务》" },
    { text: "我们的共产党和共产党所领导的八路军、新四军，是革命的队伍。我们这个队伍完全是为着解放人民的，是彻底地为人民的利益工作的。", author: "毛泽东", category: "服务", source: "《为人民服务》" },
    { text: "人总是要死的，但死的意义有不同。中国古时候有个文学家叫做司马迁的说过：人固有一死，或重于泰山，或轻于鸿毛。", author: "毛泽东", category: "人生", source: "《为人民服务》" },
    { text: "我们都是来自五湖四海，为了一个共同的革命目标，走到一起来了。", author: "毛泽东", category: "团结", source: "《为人民服务》" },
    { text: "因为我们是为人民服务的，所以，我们如果有缺点，就不怕别人批评指出。", author: "毛泽东", category: "批评", source: "《为人民服务》" },

    // 群众路线
    { text: "人民，只有人民，才是创造世界历史的动力。", author: "毛泽东", category: "人民", source: "《论联合政府》" },
    { text: "群众是真正的英雄，而我们自己则往往是幼稚可笑的。", author: "毛泽东", category: "群众", source: "《农村调查的序言和跋》" },
    { text: "从群众中来，到群众中去。", author: "毛泽东", category: "群众", source: "《关于领导方法的若干问题》" },
    { text: "一切群众的实际生活问题，都是我们应当注意的问题。", author: "毛泽东", category: "群众", source: "《关心群众生活，注意工作方法》" },
    { text: "我们应该深刻地注意群众生活的问题，从土地、劳动问题，到柴米油盐问题。", author: "毛泽东", category: "民生", source: "《关心群众生活，注意工作方法》" },
    { text: "凡是需要群众参加的工作，如果没有群众的自觉和自愿，就会流于徒有形式而失败。", author: "毛泽东", category: "群众", source: "《组织起来》" },

    // 调查研究
    { text: "没有调查，就没有发言权。", author: "毛泽东", category: "调查", source: "《反对本本主义》" },
    { text: "你要知道梨子的滋味，你就得变革梨子，亲口吃一吃。", author: "毛泽东", category: "实践", source: "《实践论》" },
    { text: "要了解情况，唯一的方法是向社会作调查。", author: "毛泽东", category: "调查", source: "《反对本本主义》" },
    { text: "不做正确的调查同样没有发言权。", author: "毛泽东", category: "调查", source: "《反对本本主义》" },
    { text: "一切结论产生于调查情况的末尾，而不是在它的先头。", author: "毛泽东", category: "调查", source: "《反对本本主义》" },

    // 革命意志
    { text: "革命不是请客吃饭，不是做文章，不是绘画绣花，不能那样雅致，那样从容不迫，文质彬彬，那样温良恭俭让。", author: "毛泽东", category: "革命", source: "《湖南农民运动考察报告》" },
    { text: "星星之火，可以燎原。", author: "毛泽东", category: "希望", source: "《星星之火，可以燎原》" },
    { text: "枪杆子里面出政权。", author: "毛泽东", category: "政权", source: "《战争和战略问题》" },
    { text: "政治是不流血的战争，战争是流血的政治。", author: "毛泽东", category: "政治", source: "《论持久战》" },
    { text: "一个革命党就怕听不到人民的声音，最可怕的是鸦雀无声。", author: "毛泽东", category: "民主", source: "《在扩大的中央工作会议上的讲话》" },

    // 学习与思考
    { text: "学而时习之，不亦说乎。", author: "毛泽东", category: "学习", source: "《改造我们的学习》" },
    { text: "好好学习，天天向上。", author: "毛泽东", category: "学习", source: "《对儿童的题词》" },
    { text: "读书是学习，使用也是学习，而且是更重要的学习。", author: "毛泽东", category: "学习", source: "《中国革命战争的战略问题》" },
    { text: "情况是在不断地变化，要使自己的思想适应新的情况，就得学习。", author: "毛泽东", category: "学习", source: "《在中国共产党全国宣传工作会议上的讲话》" },
    { text: "学习的敌人是自己的满足，要认真学习一点东西，必须从不自满开始。", author: "毛泽东", category: "学习", source: "《中国共产党在民族战争中的地位》" },

    // 自力更生
    { text: "自己动手，丰衣足食。", author: "毛泽东", category: "自立", source: "《开展根据地的减租、生产和拥政爱民运动》" },
    { text: "我们的方针要放在什么基点上？放在自己力量的基点上，叫做自力更生。", author: "毛泽东", category: "自立", source: "《抗日战争胜利后的时局和我们的方针》" },
    { text: "人定胜天。", author: "毛泽东", category: "意志", source: "《实践论》" },
    { text: "发扬勇敢战斗、不怕牺牲、不怕疲劳和连续作战的作风。", author: "毛泽东", category: "作风", source: "《中国人民解放军宣言》" },

    // 团结合作
    { text: "团结就是力量。", author: "毛泽东", category: "团结", source: "《论联合政府》" },
    { text: "全世界人民团结起来，打败美国侵略者及其一切走狗！", author: "毛泽东", category: "团结", source: "《支持美国黑人反对美帝国主义种族歧视的正义斗争的声明》" },
    { text: "中华民族有同自己的敌人血战到底的气概。", author: "毛泽东", category: "民族", source: "《论反对日本帝国主义的策略》" },
    { text: "我们中华民族有同自己的敌人血战到底的气概，有在自力更生的基础上光复旧物的决心。", author: "毛泽东", category: "民族", source: "《论反对日本帝国主义的策略》" },

    // 思想方法
    { text: "事物是运动的，变化的，进步的。", author: "毛泽东", category: "发展", source: "《矛盾论》" },
    { text: "一分为二，对立统一。", author: "毛泽东", category: "方法", source: "《矛盾论》" },
    { text: "要把事情做好，先要做人做好。", author: "毛泽东", category: "品格", source: "《为人民服务》" },
    { text: "世界是你们的，也是我们的，但是归根结底是你们的。", author: "毛泽东", category: "青年", source: "《在莫斯科大学对中国留学生的讲话》" },
    { text: "青年人朝气蓬勃，正在兴旺时期，好像早晨八九点钟的太阳。希望寄托在你们身上。", author: "毛泽东", category: "青年", source: "《在莫斯科大学对中国留学生的讲话》" },

    // 建设与发展
    { text: "备战、备荒、为人民。", author: "毛泽东", category: "建设", source: "《关于三线建设的指示》" },
    { text: "自力更生为主，争取外援为辅。", author: "毛泽东", category: "建设", source: "《抗日战争胜利后的时局和我们的方针》" },
    { text: "我们的教育方针，应该使受教育者在德育、智育、体育几方面都得到发展。", author: "毛泽东", category: "教育", source: "《关于正确处理人民内部矛盾的问题》" },
    { text: "百花齐放，百家争鸣。", author: "毛泽东", category: "文化", source: "《关于正确处理人民内部矛盾的问题》" },

    // 作风建设
    { text: "务必使同志们继续地保持谦虚、谨慎、不骄、不躁的作风。", author: "毛泽东", category: "作风", source: "《在中国共产党第七届中央委员会第二次全体会议上的报告》" },
    { text: "务必使同志们继续地保持艰苦奋斗的作风。", author: "毛泽东", category: "作风", source: "《在中国共产党第七届中央委员会第二次全体会议上的报告》" },
    { text: "我们决不当李自成，我们都希望考个好成绩。", author: "毛泽东", category: "警醒", source: "《在中国共产党第七届中央委员会第二次全体会议上的报告》" },
    { text: "批评和自我批评是一个政党强大的表现。", author: "毛泽东", category: "批评", source: "《论联合政府》" },

    // 国际视野
    { text: "中国人民从此站起来了！", author: "毛泽东", category: "独立", source: "《中国人民站起来了》" },
    { text: "我们的朋友遍天下。", author: "毛泽东", category: "友谊", source: "《关于三个世界划分的理论》" },
    { text: "帝国主义和一切反动派都是纸老虎。", author: "毛泽东", category: "斗争", source: "《和美国记者安娜·路易斯·斯特朗的谈话》" },
    { text: "中国应当对于人类有较大的贡献。", author: "毛泽东", category: "贡献", source: "《纪念孙中山先生》" },

    // 精神品质
    { text: "下定决心，不怕牺牲，排除万难，去争取胜利。", author: "毛泽东", category: "意志", source: "《愚公移山》" },
    { text: "世上无难事，只要肯登攀。", author: "毛泽东", category: "坚持", source: "《水调歌头·重上井冈山》" },
    { text: "愚公移山，改造中国。", author: "毛泽东", category: "改造", source: "《愚公移山》" },
    { text: "发扬革命传统，争取更大光荣。", author: "毛泽东", category: "传统", source: "《为人民服务》" },
    { text: "虚心使人进步，骄傲使人落后。", author: "毛泽东", category: "品格", source: "《在中国共产党全国宣传工作会议上的讲话》" },
    { text: "谦虚、谨慎、戒骄、戒躁。", author: "毛泽东", category: "品格", source: "《在中国共产党第七届中央委员会第二次全体会议上的报告》" },

    // 时间与奋斗
    { text: "一万年太久，只争朝夕。", author: "毛泽东", category: "时间", source: "《满江红·和郭沫若同志》" },
    { text: "宜将剩勇追穷寇，不可沽名学霸王。", author: "毛泽东", category: "意志", source: "《七律·人民解放军占领南京》" },
    { text: "数风流人物，还看今朝。", author: "毛泽东", category: "豪迈", source: "《沁园春·雪》" },
    { text: "俱往矣，数风流人物，还看今朝。", author: "毛泽东", category: "豪迈", source: "《沁园春·雪》" },
    { text: "雄关漫道真如铁，而今迈步从头越。", author: "毛泽东", category: "奋斗", source: "《忆秦娥·娄山关》" },
    { text: "红军不怕远征难，万水千山只等闲。", author: "毛泽东", category: "意志", source: "《七律·长征》" },
    { text: "更喜岷山千里雪，三军过后尽开颜。", author: "毛泽东", category: "乐观", source: "《七律·长征》" },

    // 历史与现实
    { text: "人民万岁！", author: "毛泽东", category: "人民", source: "《开国大典讲话》" },
    { text: "独立自主，自力更生。", author: "毛泽东", category: "独立", source: "《抗日战争胜利后的时局和我们的方针》" },
    { text: "实事求是。", author: "毛泽东", category: "作风", source: "《改造我们的学习》" },
    { text: "古为今用，洋为中用。", author: "毛泽东", category: "学习", source: "《在中国共产党全国宣传工作会议上的讲话》" },
    { text: "继往开来。", author: "毛泽东", category: "发展", source: "《新民主主义论》" }
  ];

  private static currentSource: QuoteSource = QuoteSource.MAOZEDONG;
  private static readonly QUOTE_SOURCE_KEY = 'quote_source';

  static async loadQuoteSource(): Promise<void> {
    try {
      // 在实际实现中应该使用Preferences API
      // 这里先用localStorage模拟
      const saved: string | null = globalThis.localStorage?.getItem?.(QuoteData.QUOTE_SOURCE_KEY) || null;
      if (saved && Object.values(QuoteSource).includes(saved as QuoteSource)) {
        QuoteData.currentSource = saved as QuoteSource;
      }
    } catch (error) {
      console.error('Failed to load quote source:', error);
    }
  }

  static async saveQuoteSource(source: QuoteSource): Promise<void> {
    try {
      QuoteData.currentSource = source;
      // 在实际实现中应该使用Preferences API
      // 这里先用localStorage模拟
      globalThis.localStorage?.setItem?.(QuoteData.QUOTE_SOURCE_KEY, source);
    } catch (error) {
      console.error('Failed to save quote source:', error);
    }
  }

  static setQuoteSource(source: QuoteSource): void {
    QuoteData.currentSource = source;
  }

  static getQuoteSource(): QuoteSource {
    return QuoteData.currentSource;
  }

  static getAllQuotes(): Quote[] {
    return QuoteData.currentSource === QuoteSource.SHIJING ?
      QuoteData.shijingQuotes : QuoteData.maozedongQuotes;
  }

  static getRandomQuote(): Quote {
    const quotes = QuoteData.getAllQuotes();
    return quotes[Math.floor(Math.random() * quotes.length)];
  }

  static getQuotesByCategory(category: string): Quote[] {
    return QuoteData.getAllQuotes().filter(quote => quote.category === category);
  }

  static getQuotesBySeason(season: string): Quote[] {
    return QuoteData.getAllQuotes().filter(quote => !quote.season || quote.season === season);
  }

  static getQuotesByWeather(weather: string): Quote[] {
    return QuoteData.getAllQuotes().filter(quote => !quote.weather || quote.weather === weather);
  }

  static addQuote(quote: Quote): void {
    if (QuoteData.currentSource === QuoteSource.SHIJING) {
      QuoteData.shijingQuotes.push(quote);
    } else {
      QuoteData.maozedongQuotes.push(quote);
    }
  }
}