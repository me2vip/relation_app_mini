import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/channel_provider.dart';
import '../../models/contact.dart';
import '../../models/channel.dart';

/// 联系人完整信息编辑页面
/// 包含用户规格中的所有字段：基本信息、教育、职业、个性、家庭、经济、信任、目标等
class ContactEditPage extends StatefulWidget {
  final Contact? contact; // null = 新建联系人

  const ContactEditPage({super.key, this.contact});

  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();

  // ===== 表单控制器 =====
  late TextEditingController _nameController;
  late TextEditingController _avatarController;
  late TextEditingController _ageController;
  late TextEditingController _ethnicityController;
  late TextEditingController _religionController;
  late TextEditingController _politicalController;
  late TextEditingController _schoolController;
  late TextEditingController _majorController;
  late TextEditingController _personalityTagsController;
  late TextEditingController _personalityDescController;
  late TextEditingController _characterTagsController;
  late TextEditingController _taboosController;
  late TextEditingController _valuesController;
  late TextEditingController _hobbiesController;
  late TextEditingController _strengthsController;
  late TextEditingController _weaknessesController;
  late TextEditingController _fearsController;
  late TextEditingController _desiresController;
  late TextEditingController _skillsController;
  late TextEditingController _tasteController;
  late TextEditingController _industryController;
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _workExpController;
  late TextEditingController _homeAddrController;
  late TextEditingController _familySitController;
  late TextEditingController _familyEcoController;
  late TextEditingController _familyEmoController;
  late TextEditingController _socialCirclesController;
  late TextEditingController _currentStatusController;
  late TextEditingController _shortGoalsController;
  late TextEditingController _longGoalsController;
  late TextEditingController _goalRelationController;
  late TextEditingController _tagsController;

  // ===== 下拉/枚举值 =====
  late ContactLevel _level;
  late Gender _gender;
  late MaritalStatus _maritalStatus;
  late EducationLevel _educationLevel;
  late DateTime? _birthday;
  late int _taTrust;
  late int _myTrust;
  late String _moneyDesire;
  late String _ambition;

  // ===== 社交账号 =====
  List<ContactMethod> _methods = [];

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nameController      = TextEditingController(text: c?.name ?? '');
    _avatarController    = TextEditingController(text: c?.avatar ?? '');
    _ageController       = TextEditingController(text: c?.age?.toString() ?? '');
    _ethnicityController = TextEditingController(text: c?.ethnicity ?? '');
    _religionController  = TextEditingController(text: c?.religion ?? '');
    _politicalController = TextEditingController(text: c?.politicalAffiliation ?? '');
    _schoolController    = TextEditingController(text: c?.school ?? '');
    _majorController     = TextEditingController(text: c?.major ?? '');
    _personalityTagsController = TextEditingController(text: c?.personalityTags ?? '');
    _personalityDescController = TextEditingController(text: c?.personalityDesc ?? '');
    _characterTagsController  = TextEditingController(text: c?.characterTags ?? '');
    _taboosController    = TextEditingController(text: c?.taboos ?? '');
    _valuesController    = TextEditingController(text: c?.values ?? '');
    _hobbiesController   = TextEditingController(text: c?.hobbies ?? '');
    _strengthsController = TextEditingController(text: c?.strengths ?? '');
    _weaknessesController= TextEditingController(text: c?.weaknesses ?? '');
    _fearsController    = TextEditingController(text: c?.fears ?? '');
    _desiresController  = TextEditingController(text: c?.desires ?? '');
    _skillsController   = TextEditingController(text: c?.skills ?? '');
    _tasteController    = TextEditingController(text: c?.tastePreferences ?? '');
    _industryController = TextEditingController(text: c?.industry ?? '');
    _companyController  = TextEditingController(text: c?.company ?? '');
    _positionController = TextEditingController(text: c?.position ?? '');
    _workExpController  = TextEditingController(text: c?.workExperience ?? '');
    _homeAddrController = TextEditingController(text: c?.homeAddress ?? '');
    _familySitController= TextEditingController(text: c?.familySituation ?? '');
    _familyEcoController= TextEditingController(text: c?.familyEconomicStatus ?? '');
    _familyEmoController= TextEditingController(text: c?.familyEmotionalStatus ?? '');
    _socialCirclesController = TextEditingController(text: c?.socialCircles ?? '');
    _currentStatusController = TextEditingController(text: c?.currentStatus ?? '');
    _shortGoalsController= TextEditingController(text: c?.shortTermGoals ?? '');
    _longGoalsController= TextEditingController(text: c?.longTermGoals ?? '');
    _goalRelationController = TextEditingController(text: c?.goalRelation ?? '');
    _tagsController     = TextEditingController(text: (c?.tags ?? []).join('、'));

    _level         = c?.level ?? ContactLevel.normal;
    _gender        = c?.gender ?? Gender.unknown;
    _maritalStatus = c?.maritalStatus ?? MaritalStatus.unknown;
    _educationLevel= c?.educationLevel ?? EducationLevel.unknown;
    _birthday      = c?.birthday;
    _taTrust       = c?.taTrustLevel ?? 5;
    _myTrust       = c?.myTrustLevel ?? 5;
    _moneyDesire   = c?.moneyDesireLevel ?? '3';
    _ambition      = c?.ambitionLevel ?? '3';
    _methods       = List.from(c?.methods ?? []);
  }

  @override
  void dispose() {
    for (var c in [
      _nameController, _avatarController, _ageController, _ethnicityController,
      _religionController, _politicalController, _schoolController, _majorController,
      _personalityTagsController, _personalityDescController, _characterTagsController,
      _taboosController, _valuesController, _hobbiesController, _strengthsController,
      _weaknessesController, _fearsController, _desiresController, _skillsController,
      _tasteController, _industryController, _companyController, _positionController,
      _workExpController, _homeAddrController, _familySitController, _familyEcoController,
      _familyEmoController, _socialCirclesController, _currentStatusController,
      _shortGoalsController, _longGoalsController, _goalRelationController, _tagsController,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _addMethod() {
    final platformCtrl = TextEditingController();
    final accountCtrl  = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加社交账号'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快捷选择
            Wrap(
              spacing: 6,
              children: ['微信','QQ','抖音','快手','小红书','微博'].map((p) =>
                ActionChip(label: Text(p), onPressed: () {
                  platformCtrl.text = p;
                }),
              ).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: platformCtrl, decoration: const InputDecoration(labelText: '平台/渠道')),
            const SizedBox(height: 8),
            TextField(controller: accountCtrl, decoration: const InputDecoration(labelText: '账号/ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            if (platformCtrl.text.isNotEmpty && accountCtrl.text.isNotEmpty) {
              setState(() {
                _methods.add(ContactMethod(
                  id: _uuid.v4(),
                  platform: platformCtrl.text,
                  account: accountCtrl.text,
                  createdAt: DateTime.now(),
                ));
              });
            }
            Navigator.pop(ctx);
          }, child: const Text('添加')),
        ],
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _birthday = d);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ContactProvider>();
    final now = DateTime.now();
    final tags = _tagsController.text.isEmpty
        ? <String>[]
        : _tagsController.text.split(RegExp(r'[,，、\n]')).where((t) => t.trim().isNotEmpty).toList();
    final age = int.tryParse(_ageController.text);

    final contact = Contact(
      id: widget.contact?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      avatar: _avatarController.text.trim().isEmpty ? null : _avatarController.text.trim(),
      level: _level,
      gender: _gender,
      birthday: _birthday,
      age: age,
      ethnicity: _ethnicityController.text.trim().isEmpty ? null : _ethnicityController.text.trim(),
      religion: _religionController.text.trim().isEmpty ? null : _religionController.text.trim(),
      politicalAffiliation: _politicalController.text.trim().isEmpty ? null : _politicalController.text.trim(),
      maritalStatus: _maritalStatus,
      educationLevel: _educationLevel,
      school: _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
      major: _majorController.text.trim().isEmpty ? null : _majorController.text.trim(),
      personalityTags: _personalityTagsController.text.trim().isEmpty ? null : _personalityTagsController.text.trim(),
      personalityDesc: _personalityDescController.text.trim().isEmpty ? null : _personalityDescController.text.trim(),
      characterTags: _characterTagsController.text.trim().isEmpty ? null : _characterTagsController.text.trim(),
      taboos: _taboosController.text.trim().isEmpty ? null : _taboosController.text.trim(),
      values: _valuesController.text.trim().isEmpty ? null : _valuesController.text.trim(),
      hobbies: _hobbiesController.text.trim().isEmpty ? null : _hobbiesController.text.trim(),
      strengths: _strengthsController.text.trim().isEmpty ? null : _strengthsController.text.trim(),
      weaknesses: _weaknessesController.text.trim().isEmpty ? null : _weaknessesController.text.trim(),
      fears: _fearsController.text.trim().isEmpty ? null : _fearsController.text.trim(),
      desires: _desiresController.text.trim().isEmpty ? null : _desiresController.text.trim(),
      skills: _skillsController.text.trim().isEmpty ? null : _skillsController.text.trim(),
      tastePreferences: _tasteController.text.trim().isEmpty ? null : _tasteController.text.trim(),
      industry: _industryController.text.trim().isEmpty ? null : _industryController.text.trim(),
      company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
      workExperience: _workExpController.text.trim().isEmpty ? null : _workExpController.text.trim(),
      homeAddress: _homeAddrController.text.trim().isEmpty ? null : _homeAddrController.text.trim(),
      familySituation: _familySitController.text.trim().isEmpty ? null : _familySitController.text.trim(),
      familyEconomicStatus: _familyEcoController.text.trim().isEmpty ? null : _familyEcoController.text.trim(),
      familyEmotionalStatus: _familyEmoController.text.trim().isEmpty ? null : _familyEmoController.text.trim(),
      taTrustLevel: _taTrust,
      myTrustLevel: _myTrust,
      socialCircles: _socialCirclesController.text.trim().isEmpty ? null : _socialCirclesController.text.trim(),
      currentStatus: _currentStatusController.text.trim().isEmpty ? null : _currentStatusController.text.trim(),
      moneyDesireLevel: _moneyDesire,
      ambitionLevel: _ambition,
      shortTermGoals: _shortGoalsController.text.trim().isEmpty ? null : _shortGoalsController.text.trim(),
      longTermGoals: _longGoalsController.text.trim().isEmpty ? null : _longGoalsController.text.trim(),
      goalRelation: _goalRelationController.text.trim().isEmpty ? null : _goalRelationController.text.trim(),
      methods: _methods,
      tags: tags,
      groupId: widget.contact?.groupId,
      createdAt: widget.contact?.createdAt ?? now,
      updatedAt: now,
      interactions: widget.contact?.interactions ?? [],
    );

    if (_isEditing) {
      provider.updateContact(contact);
    } else {
      provider.addContact(contact);
    }
    Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑联系人' : '新建联系人'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ===== 区块1：基本信息 =====
            _sectionHeader('基本信息'),
            _requiredField(TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: '姓名 *'))),
            _field(TextFormField(controller: _avatarController, decoration: const InputDecoration(labelText: '头像URL', hintText: '输入头像图片地址'))),
            _dropdown<ContactLevel>('重要层级', _level, ContactLevel.values, (v) => v.name, (v) {
              setState(() => _level = v);
            }),
            _dropdown<Gender>('性别', _gender, Gender.values, (v) => v.name, (v) {
              setState(() => _gender = v);
            }),
            Row(children: [
              Expanded(child: _field(TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '年龄'),
              ))),
              Expanded(child: _field(InkWell(
                onTap: _pickBirthday,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '生日'),
                  child: Text(_birthday != null
                    ? DateFormat('yyyy-MM-dd').format(_birthday!)
                    : '点击选择', style: TextStyle(color: Colors.grey[600])),
                ),
              ))),
            ]),
            _field(TextFormField(controller: _ethnicityController, decoration: const InputDecoration(labelText: '民族', hintText: '如：汉族'))),
            _field(TextFormField(controller: _religionController, decoration: const InputDecoration(labelText: '宗教信仰', hintText: '如：无'))),
            _field(TextFormField(controller: _politicalController, decoration: const InputDecoration(labelText: '政治面貌', hintText: '如：群众'))),
            _dropdown<MaritalStatus>('婚姻状况', _maritalStatus, MaritalStatus.values, (v) => v.name, (v) {
              setState(() => _maritalStatus = v);
            }),

            const SizedBox(height: 12),
            // ===== 区块2：教育背景 =====
            _sectionHeader('教育背景'),
            _dropdown<EducationLevel>('学历', _educationLevel, EducationLevel.values, (v) => v.name, (v) {
              setState(() => _educationLevel = v);
            }),
            _field(TextFormField(controller: _schoolController, decoration: const InputDecoration(labelText: '学校', hintText: '毕业院校'))),
            _field(TextFormField(controller: _majorController, decoration: const InputDecoration(labelText: '专业', hintText: '所学专业'))),

            const SizedBox(height: 12),
            // ===== 区块3：职业信息 =====
            _sectionHeader('职业信息'),
            _field(TextFormField(controller: _industryController, decoration: const InputDecoration(labelText: '当前行业', hintText: '如：互联网、金融'))),
            _field(TextFormField(controller: _companyController, decoration: const InputDecoration(labelText: '公司', hintText: '就职公司'))),
            _field(TextFormField(controller: _positionController, decoration: const InputDecoration(labelText: '职位', hintText: '当前职位'))),
            _field(TextFormField(controller: _workExpController, decoration: const InputDecoration(labelText: '过往经历', hintText: '以前做过的行业或职位'), maxLines: 2)),

            const SizedBox(height: 12),
            // ===== 区块4：个性与价值观 =====
            _sectionHeader('个性与价值观'),
            _field(TextFormField(controller: _personalityTagsController, decoration: const InputDecoration(labelText: '性格标签', hintText: '如：外向、内敛，用顿号或逗号分隔'))),
            _field(TextFormField(controller: _personalityDescController, decoration: const InputDecoration(labelText: '性格详细描述', hintText: '详细描述此人的性格特点'), maxLines: 3)),
            _field(TextFormField(controller: _characterTagsController, decoration: const InputDecoration(labelText: '人品标签', hintText: '如：守信、仗义，用顿号分隔'))),
            _field(TextFormField(controller: _taboosController, decoration: const InputDecoration(labelText: '大忌', hintText: '绝对不能触碰的雷区'), maxLines: 2)),
            _field(TextFormField(controller: _valuesController, decoration: const InputDecoration(labelText: '价值观', hintText: '此人看重什么'), maxLines: 2)),

            const SizedBox(height: 12),
            // ===== 区块5：个人特质 =====
            _sectionHeader('个人特质'),
            _field(TextFormField(controller: _hobbiesController, decoration: const InputDecoration(labelText: '兴趣爱好', hintText: '兴趣爱好描述'), maxLines: 2)),
            _field(TextFormField(controller: _strengthsController, decoration: const InputDecoration(labelText: '优点', hintText: '长处和优势'), maxLines: 2)),
            _field(TextFormField(controller: _weaknessesController, decoration: const InputDecoration(labelText: '缺点', hintText: '不足和弱点'), maxLines: 2)),
            _field(TextFormField(controller: _fearsController, decoration: const InputDecoration(labelText: '恐惧', hintText: '最害怕什么'), maxLines: 2)),
            _field(TextFormField(controller: _desiresController, decoration: const InputDecoration(labelText: '渴望', hintText: '内心最渴望什么'), maxLines: 2)),
            _field(TextFormField(controller: _skillsController, decoration: const InputDecoration(labelText: '技能与能力', hintText: '擅长什么'), maxLines: 2)),
            _field(TextFormField(controller: _tasteController, decoration: const InputDecoration(labelText: '口味偏好', hintText: '喜欢什么口味、食物偏好'), maxLines: 2)),

            const SizedBox(height: 12),
            // ===== 区块6：家庭信息 =====
            _sectionHeader('家庭信息'),
            _field(TextFormField(controller: _homeAddrController, decoration: const InputDecoration(labelText: '家庭住址', hintText: '大致位置'), maxLines: 2)),
            _field(TextFormField(controller: _familySitController, decoration: const InputDecoration(labelText: '家庭情况', hintText: '家庭成员构成'), maxLines: 2)),
            _field(TextFormField(controller: _familyEcoController, decoration: const InputDecoration(labelText: '家庭经济状况', hintText: '经济条件描述'), maxLines: 2)),
            _field(TextFormField(controller: _familyEmoController, decoration: const InputDecoration(labelText: '家庭感情状况', hintText: '家庭关系如何'), maxLines: 2)),

            const SizedBox(height: 12),
            // ===== 区块7：信任与关系 =====
            _sectionHeader('信任与关系'),
            _sliderField('TA对我的信任度', _taTrust, (v) => setState(() => _taTrust = v)),
            _sliderField('我对TA的信任度', _myTrust, (v) => setState(() => _myTrust = v)),
            _field(TextFormField(controller: _socialCirclesController, decoration: const InputDecoration(labelText: '所交往圈子', hintText: 'TA的社交圈子，如：程序员、创业者'), maxLines: 2)),
            _field(TextFormField(controller: _currentStatusController, decoration: const InputDecoration(labelText: '目前现状', hintText: '目前生活/工作状态'), maxLines: 2)),

            const SizedBox(height: 12),
            // ===== 区块8：目标与欲望 =====
            _sectionHeader('目标与欲望'),
            _sliderField('挣钱欲望 (1-5)', int.tryParse(_moneyDesire) ?? 3, (v) {
              setState(() => _moneyDesire = v.toString());
            }),
            _sliderField('上进心 (1-5)', int.tryParse(_ambition) ?? 3, (v) {
              setState(() => _ambition = v.toString());
            }),
            _field(TextFormField(controller: _shortGoalsController, decoration: const InputDecoration(labelText: '短期目标', hintText: '最近几个月想达成的目标'), maxLines: 2)),
            _field(TextFormField(controller: _longGoalsController, decoration: const InputDecoration(labelText: '长期目标', hintText: '未来几年的规划'), maxLines: 2)),
            _field(TextFormField(controller: _goalRelationController, decoration: const InputDecoration(labelText: '目标关系定位', hintText: '你想和此人建立怎样的关系'), maxLines: 2)),

            const SizedBox(height: 12),
            // ===== 区块9：系统字段 =====
            _sectionHeader('社交账号'),
            if (_methods.isNotEmpty)
              ...(_methods.map((m) => ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline),
                title: Text(m.platform),
                subtitle: Text(m.account),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _methods.remove(m))),
              ))),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('添加社交账号'), onPressed: _addMethod),
            const SizedBox(height: 8),
            _field(TextFormField(controller: _tagsController, decoration: const InputDecoration(labelText: '自定义标签', hintText: '多个标签用顿号或逗号分隔'), maxLines: 2)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 6),
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
  );

  Widget _field(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 8), child: child);

  Widget _requiredField(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 8), child: child);

  Widget _dropdown<T>(String label, T value, List<T> items, String Function(T) labelBuilder, void Function(T) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  Widget _sliderField(String label, int value, void Function(int) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text('$value', style: const TextStyle(fontWeight: FontWeight.bold))]),
        ),
        Slider(value: value.toDouble(), min: 1, max: 10, divisions: 9,
          onChanged: (v) => onChanged(v.round())),
      ],
    ),
  );
}
