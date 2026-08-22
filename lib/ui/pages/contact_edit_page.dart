import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/contact_provider.dart';
import '../../core/providers/channel_config_provider.dart';
import '../../core/providers/channel_provider.dart';
import '../../models/contact.dart';
import '../../models/channel.dart';
import '../../models/social_channel_config.dart';

const Map<ContactLevel, String> _levelNames = {
  ContactLevel.unimportant: '不重要',
  ContactLevel.normal: '一般',
  ContactLevel.important: '重要',
  ContactLevel.core: '核心',
};

const Map<Gender, String> _genderNames = {
  Gender.unknown: '未知',
  Gender.male: '男',
  Gender.female: '女',
};

const Map<MaritalStatus, String> _maritalNames = {
  MaritalStatus.unknown: '未知',
  MaritalStatus.single: '单身',
  MaritalStatus.married: '已婚',
  MaritalStatus.divorced: '离异',
  MaritalStatus.widowed: '丧偶',
  MaritalStatus.inRelationship: '恋爱中',
};

const Map<EducationLevel, String> _eduNames = {
  EducationLevel.unknown: '未知',
  EducationLevel.highSchool: '高中',
  EducationLevel.vocational: '中专/职高',
  EducationLevel.associate: '大专',
  EducationLevel.bachelor: '本科',
  EducationLevel.master: '硕士',
  EducationLevel.doctoral: '博士',
};

final _kSectionColors = <Color>[
  const Color(0xFFFF6B6B),
  const Color(0xFF4ECDC4),
  const Color(0xFF45B7D1),
  const Color(0xFF96CEB4),
  const Color(0xFFFFEAA7),
  const Color(0xFFDDA0DD),
  const Color(0xFF98D8C8),
  const Color(0xFFF7DC6F),
  const Color(0xFFBB8FCE),
  const Color(0xFF85C1E9),
];

class ContactEditPage extends StatefulWidget {
  final Contact? contact;
  const ContactEditPage({super.key, this.contact});

  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();

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

  late ContactLevel _level;
  late Gender _gender;
  late MaritalStatus _maritalStatus;
  late EducationLevel _educationLevel;
  late DateTime? _birthday;
  late int _taTrust;
  late int _myTrust;
  late String _moneyDesire;
  late String _ambition;

  List<ContactMethod> _methods = [];
  List<ContactChannelConfig> _pendingChannelConfigs = [];

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_add_alt, color: Colors.deepOrange),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('添加社交账号',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('快捷选择', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['微信','QQ','抖音','快手','小红书','微博'].map((p) =>
                    ChoiceChip(
                      label: Text(p),
                      selected: platformCtrl.text == p,
                      onSelected: (_) {
                        setDialogState(() => platformCtrl.text = p);
                      },
                      selectedColor: Colors.deepOrange.withOpacity(0.2),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide.none,
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: platformCtrl,
                  decoration: _modernInputDecoration('平台/渠道', '如：微信, QQ'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountCtrl,
                  decoration: _modernInputDecoration('账号/ID', '输入账号或ID'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF758F), Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () {
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
                        },
                        child: const Text('添加', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF4757),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _birthday = d);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ContactProvider>();
    final channelProvider = context.read<ChannelConfigProvider>();
    final now = DateTime.now();
    final tags = _tagsController.text.isEmpty
        ? <String>[]
        : _tagsController.text.split(RegExp(r'[,，、\n]')).where((t) => t.trim().isNotEmpty).toList();
    final age = int.tryParse(_ageController.text);
    final id = widget.contact?.id ?? _uuid.v4();

    final contact = Contact(
      id: id,
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

    for (final config in _pendingChannelConfigs) {
      channelProvider.addConfig(
        contactId: id,
        channelId: config.channelId,
        platform: config.platform,
        account: config.account,
        remark: config.remark,
        enabledFeatures: config.enabledFeatures,
        preferredModes: config.preferredModes,
        isPrimary: config.isPrimary,
      );
    }

    Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF758F), Color(0xFFFF4757), Color(0xFFFF6B6B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                      children: [
                        _buildSection(
                          index: 0,
                          title: '基本信息',
                          subtitle: '姓名、性别、年龄等',
                          icon: Icons.person_outline,
                          children: [
                            _requiredField(TextFormField(
                              controller: _nameController,
                              decoration: _modernInputDecoration('姓名 *', '请输入姓名'),
                              validator: (v) => v?.trim().isEmpty ?? true ? '请输入姓名' : null,
                            )),
                            _field(TextFormField(
                              controller: _avatarController,
                              decoration: _modernInputDecoration('头像URL', '输入头像图片地址'),
                            )),
                            _buildDropdown<ContactLevel>('重要层级', _level, ContactLevel.values, _levelNames, (v) => setState(() => _level = v)),
                            _buildDropdown<Gender>('性别', _gender, Gender.values, _genderNames, (v) => setState(() => _gender = v)),
                            Row(
                              children: [
                                Expanded(child: _field(TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: _modernInputDecoration('年龄', ''),
                                ))),
                                const SizedBox(width: 12),
                                Expanded(child: _field(InkWell(
                                  onTap: _pickBirthday,
                                  child: InputDecorator(
                                    decoration: _modernInputDecoration('生日', ''),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _birthday != null
                                              ? DateFormat('yyyy-MM-dd').format(_birthday!)
                                              : '点击选择',
                                          style: TextStyle(
                                            color: _birthday != null ? Colors.black87 : Colors.grey,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ))),
                              ],
                            ),
                            _field(TextFormField(
                              controller: _ethnicityController,
                              decoration: _modernInputDecoration('民族', '如：汉族'),
                            )),
                            _field(TextFormField(
                              controller: _religionController,
                              decoration: _modernInputDecoration('宗教信仰', '如：无'),
                            )),
                            _field(TextFormField(
                              controller: _politicalController,
                              decoration: _modernInputDecoration('政治面貌', '如：群众'),
                            )),
                            _buildDropdown<MaritalStatus>('婚姻状况', _maritalStatus, MaritalStatus.values, _maritalNames, (v) => setState(() => _maritalStatus = v)),
                          ],
                        ),
                        _buildSection(
                          index: 1,
                          title: '教育背景',
                          subtitle: '学历、学校、专业',
                          icon: Icons.school_outlined,
                          children: [
                            _buildDropdown<EducationLevel>('学历', _educationLevel, EducationLevel.values, _eduNames, (v) => setState(() => _educationLevel = v)),
                            _field(TextFormField(
                              controller: _schoolController,
                              decoration: _modernInputDecoration('学校', '毕业院校'),
                            )),
                            _field(TextFormField(
                              controller: _majorController,
                              decoration: _modernInputDecoration('专业', '所学专业'),
                            )),
                          ],
                        ),
                        _buildSection(
                          index: 2,
                          title: '职业信息',
                          subtitle: '行业、公司、职位',
                          icon: Icons.work_outline,
                          children: [
                            _field(TextFormField(
                              controller: _industryController,
                              decoration: _modernInputDecoration('当前行业', '如：互联网、金融'),
                            )),
                            _field(TextFormField(
                              controller: _companyController,
                              decoration: _modernInputDecoration('公司', '就职公司'),
                            )),
                            _field(TextFormField(
                              controller: _positionController,
                              decoration: _modernInputDecoration('职位', '当前职位'),
                            )),
                            _field(TextFormField(
                              controller: _workExpController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('过往经历', '以前做过的行业或职位'),
                            )),
                          ],
                        ),
                        _buildSection(
                          index: 3,
                          title: '个性与价值观',
                          subtitle: '性格、人品、价值观',
                          icon: Icons.auto_awesome_outlined,
                          children: [
                            _field(TextFormField(
                              controller: _personalityTagsController,
                              decoration: _modernInputDecoration('性格标签', '如：外向、内敛，用顿号或逗号分隔'),
                            )),
                            _field(TextFormField(
                              controller: _personalityDescController,
                              maxLines: 3,
                              decoration: _modernInputDecoration('性格详细描述', '详细描述此人的性格特点'),
                            )),
                            _field(TextFormField(
                              controller: _characterTagsController,
                              decoration: _modernInputDecoration('人品标签', '如：守信、仗义，用顿号分隔'),
                            )),
                            _field(TextFormField(
                              controller: _taboosController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('大忌', '绝对不能触碰的雷区'),
                            )),
                            _field(TextFormField(
                              controller: _valuesController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('价值观', '此人看重什么'),
                            )),
                          ],
                        ),
                        _buildSection(
                          index: 4,
                          title: '个人特质',
                          subtitle: '爱好、优缺点、技能',
                          icon: Icons.emoji_events_outlined,
                          children: [
                            _field(TextFormField(
                              controller: _hobbiesController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('兴趣爱好', '兴趣爱好描述'),
                            )),
                            _field(TextFormField(
                              controller: _strengthsController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('优点', '长处和优势'),
                            )),
                            _field(TextFormField(
                              controller: _weaknessesController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('缺点', '不足和弱点'),
                            )),
                            _field(TextFormField(
                              controller: _fearsController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('恐惧', '最害怕什么'),
                            )),
                            _field(TextFormField(
                              controller: _desiresController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('渴望', '内心最渴望什么'),
                            )),
                            _field(TextFormField(
                              controller: _skillsController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('技能与能力', '擅长什么'),
                            )),
                            _field(TextFormField(
                              controller: _tasteController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('口味偏好', '喜欢什么口味、食物偏好'),
                            )),
                          ],
                        ),
                        _buildSection(
                          index: 5,
                          title: '家庭信息',
                          subtitle: '住址、家庭状况',
                          icon: Icons.home_outlined,
                          children: [
                            _field(TextFormField(
                              controller: _homeAddrController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('家庭住址', '大致位置'),
                            )),
                            _field(TextFormField(
                              controller: _familySitController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('家庭情况', '家庭成员构成'),
                            )),
                            _field(TextFormField(
                              controller: _familyEcoController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('家庭经济状况', '经济条件描述'),
                            )),
                            _field(TextFormField(
                              controller: _familyEmoController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('家庭感情状况', '家庭关系如何'),
                            )),
                          ],
                        ),
                        _buildSection(
                          index: 6,
                          title: '信任与关系',
                          subtitle: '信任度、社交圈',
                          icon: Icons.verified_user_outlined,
                          children: [
                            _buildSlider('TA对我的信任度', _taTrust, (v) => setState(() => _taTrust = v)),
                            _buildSlider('我对TA的信任度', _myTrust, (v) => setState(() => _myTrust = v)),
                            _field(TextFormField(
                              controller: _socialCirclesController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('所交往圈子', 'TA的社交圈子，如：程序员、创业者'),
                            )),
                            _field(TextFormField(
                              controller: _currentStatusController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('目前现状', '目前生活/工作状态'),
                            )),
                          ],
                        ),
                        _buildSection(
                          index: 7,
                          title: '目标与欲望',
                          subtitle: '目标、上进心',
                          icon: Icons.flag_outlined,
                          children: [
                            _buildSlider('挣钱欲望 (1-5)', int.tryParse(_moneyDesire) ?? 3, (v) {
                              setState(() => _moneyDesire = v.toString());
                            }),
                            _buildSlider('上进心 (1-5)', int.tryParse(_ambition) ?? 3, (v) {
                              setState(() => _ambition = v.toString());
                            }),
                            _field(TextFormField(
                              controller: _shortGoalsController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('短期目标', '最近几个月想达成的目标'),
                            )),
                            _field(TextFormField(
                              controller: _longGoalsController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('长期目标', '未来几年的规划'),
                            )),
                            _field(TextFormField(
                              controller: _goalRelationController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('目标关系定位', '你想和此人建立怎样的关系'),
                            )),
                          ],
                        ),
                        Consumer<ChannelConfigProvider>(
                          builder: (ctx, channelProvider, _) {
                            final existingConfigs = _isEditing
                                ? channelProvider.getConfigsForContact(widget.contact!.id)
                                : const <ContactChannelConfig>[];
                            final allConfigs = [...existingConfigs, ..._pendingChannelConfigs];

                            return _buildSection(
                              index: 8,
                              title: '社交途径',
                              subtitle: '管理各平台渠道配置',
                              icon: Icons.link_outlined,
                              children: [
                                if (allConfigs.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange.withOpacity( 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.link_off, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text('暂无社交途径配置，点击下方按钮添加',
                                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (allConfigs.isNotEmpty)
                                  ...allConfigs.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final config = entry.value;
                                    final isPending = idx >= existingConfigs.length;
                                    return _buildChannelConfigCard(
                                      config: config,
                                      isPending: isPending,
                                      onRemove: () {
                                        setState(() {
                                          if (isPending) {
                                            _pendingChannelConfigs.removeAt(idx - existingConfigs.length);
                                          } else {
                                            channelProvider.removeConfig(widget.contact!.id, config.id);
                                          }
                                        });
                                      },
                                      onUpdate: (updated) {
                                        setState(() {
                                          if (isPending) {
                                            final pIdx = idx - existingConfigs.length;
                                            _pendingChannelConfigs[pIdx] = updated;
                                          } else {
                                            channelProvider.updateConfig(
                                              contactId: widget.contact!.id,
                                              configId: config.id,
                                              account: updated.account,
                                              remark: updated.remark,
                                              enabledFeatures: updated.enabledFeatures,
                                              preferredModes: updated.preferredModes,
                                              isPrimary: updated.isPrimary,
                                            );
                                          }
                                        });
                                      },
                                    );
                                  }),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF758F), Color(0xFFFF4757)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.add_circle_outline),
                                      label: const Text('添加社交途径', style: TextStyle(fontWeight: FontWeight.w600)),
                                      onPressed: () {
                                        final usedChannelIds = <String>{
                                          ...existingConfigs.map((c) => c.channelId).where((id) => id.isNotEmpty),
                                          ..._pendingChannelConfigs.map((c) => c.channelId).where((id) => id.isNotEmpty),
                                        };
                                        _addChannelConfig(channelProvider, existingConfigs.length, usedChannelIds);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        _buildSection(
                          index: 9,
                          title: '标签',
                          subtitle: '自定义标签描述',
                          icon: Icons.label_outline,
                          children: [
                            _field(TextFormField(
                              controller: _tagsController,
                              maxLines: 2,
                              decoration: _modernInputDecoration('自定义标签', '多个标签用顿号或逗号分隔'),
                            )),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _isEditing ? '编辑联系人' : '新建联系人',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity( 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final color = _kSectionColors[index % _kSectionColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity( 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        )),
                    ],
                  ),
                ),
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  InputDecoration _modernInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF4757), width: 1.5),
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFFFF4757), fontWeight: FontWeight.w600),
      labelStyle: TextStyle(color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _field(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: child,
  );

  Widget _requiredField(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: child,
  );

  Widget _buildDropdown<T>(String label, T value, List<T> items, Map<T, String> names, ValueChanged<T> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: _modernInputDecoration(label, ''),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(names[e] ?? e.toString()))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.expand_more, color: Colors.grey),
      ),
    );
  }

  Widget _buildSlider(String label, int value, void Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF758F), Color(0xFFFF4757)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$value',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(context).copyWith(
                sliderTheme: SliderThemeData(
                  activeTrackColor: const Color(0xFFFF4757),
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: const Color(0xFFFF4757),
                  overlayColor: const Color(0xFFFF4757).withOpacity( 0.12),
                  trackHeight: 4,
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addChannelConfig(ChannelConfigProvider channelProvider, int existingCount, Set<String> usedChannelIds) {
    final allChannels = context.read<ChannelProvider>().channels;
    // 过滤掉已使用过的渠道（避免同一联系人重复添加）
    final availableChannels = allChannels.where((ch) => !usedChannelIds.contains(ch.id)).toList();
    if (availableChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加所有可用途径，无需重复添加')),
      );
      return;
    }
    SocialChannel selectedChannel = availableChannels.first;
    SocialPlatform getPlatform() => selectedChannel.platform;
    PlatformConfig getPlatformCfg() => resolvePlatformConfig(
          getPlatform(), selectedChannel.name, selectedChannel.icon,
        );
    final accountCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    List<ChannelFeature> enabledFeatures = [];
    List<InteractionMode> preferredModes = [];
    bool isPrimary = _pendingChannelConfigs.isEmpty && existingCount == 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757).withOpacity( 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.link, color: Color(0xFFFF4757)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('添加社交途径',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('选择途径', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: availableChannels.map((ch) {
                        final cfg = resolvePlatformConfig(
                          ch.platform, ch.name, ch.icon,
                        );
                        final selected = ch.id == selectedChannel.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setDialogState(() {
                              selectedChannel = ch;
                              enabledFeatures = [];
                              preferredModes = [];
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? cfg.color.withOpacity(0.15) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? cfg.color : Colors.transparent,
                                  width: selected ? 2 : 0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(ch.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(ch.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selected ? cfg.color : Colors.black54,
                                    )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: accountCtrl, decoration: _modernInputDecoration('账号/ID', '输入账号')),
                  const SizedBox(height: 12),
                  TextField(controller: remarkCtrl, decoration: _modernInputDecoration('备注', '可选')),
                  const SizedBox(height: 16),
                  const Text('启用功能', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildFeatureChips(getPlatform(), enabledFeatures, setDialogState),
                  const SizedBox(height: 16),
                  const Text('偏好互动方式', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildModeChips(preferredModes, setDialogState),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withOpacity( 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      value: isPrimary,
                      onChanged: (v) => setDialogState(() => isPrimary = v),
                      title: const Text('设为主要渠道',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('优先使用此平台进行互动', style: TextStyle(fontSize: 12)),
                      activeColor: const Color(0xFFFF4757),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF758F), Color(0xFFFF4757)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: () {
                            final platform = getPlatform();
                            final config = ContactChannelConfig(
                              id: _uuid.v4(),
                              contactId: widget.contact?.id ?? '_pending',
                              channelId: selectedChannel.id,
                              platform: platform,
                              account: accountCtrl.text.trim().isEmpty ? null : accountCtrl.text.trim(),
                              remark: remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim(),
                              enabledFeatures: enabledFeatures,
                              preferredModes: preferredModes,
                              isPrimary: isPrimary,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            if (_isEditing) {
                              channelProvider.addConfig(
                                contactId: widget.contact!.id,
                                channelId: selectedChannel.id,
                                platform: platform,
                                account: config.account,
                                remark: config.remark,
                                enabledFeatures: enabledFeatures,
                                preferredModes: preferredModes,
                                isPrimary: isPrimary,
                              );
                            } else {
                              setState(() => _pendingChannelConfigs.add(config));
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('添加', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChips(SocialPlatform platform, List<ChannelFeature> enabled, StateSetter setState) {
    final platformConfig = getPlatformConfig(platform);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: platformConfig.features.map((f) {
        final selected = enabled.contains(f.feature);
        return ChoiceChip(
          label: Text('${f.emoji} ${f.name}'),
          selected: selected,
          onSelected: (_) {
            setState(() {
              if (selected) {
                enabled.remove(f.feature);
              } else {
                enabled.add(f.feature);
              }
            });
          },
          selectedColor: const Color(0xFFFF4757).withOpacity( 0.15),
          backgroundColor: Colors.grey.shade100,
          side: BorderSide(
            color: selected ? const Color(0xFFFF4757) : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
          labelStyle: TextStyle(
            color: selected ? const Color(0xFFFF4757) : Colors.black54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeChips(List<InteractionMode> selectedModes, StateSetter setState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kInteractionModeConfigs.map((m) {
        final selected = selectedModes.contains(m.mode);
        return ChoiceChip(
          label: Text('${m.emoji} ${m.name}'),
          selected: selected,
          onSelected: (_) {
            setState(() {
              if (selected) {
                selectedModes.remove(m.mode);
              } else {
                selectedModes.add(m.mode);
              }
            });
          },
          selectedColor: const Color(0xFF45B7D1).withOpacity( 0.15),
          backgroundColor: Colors.grey.shade100,
          side: BorderSide(
            color: selected ? const Color(0xFF45B7D1) : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
          labelStyle: TextStyle(
            color: selected ? const Color(0xFF45B7D1) : Colors.black54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChannelConfigCard({
    required ContactChannelConfig config,
    required bool isPending,
    required VoidCallback onRemove,
    required void Function(ContactChannelConfig) onUpdate,
  }) {
    final platformConfig = getPlatformConfig(config.platform);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: platformConfig.color.withOpacity( 0.3)),
        boxShadow: [
          BoxShadow(
            color: platformConfig.color.withOpacity( 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: platformConfig.color.withOpacity( 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(platformConfig.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(platformConfig.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          if (config.isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4757),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('主要',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          if (isPending) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity( 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('待保存',
                                style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      if (config.account != null && config.account!.isNotEmpty)
                        Text(config.account!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ),
            if (config.enabledFeatures.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('启用功能', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: config.enabledFeatures.map((f) {
                  final fc = getFeatureConfig(f);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: platformConfig.color.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${fc.emoji} ${fc.name}',
                      style: TextStyle(fontSize: 11, color: platformConfig.color, fontWeight: FontWeight.w500)),
                  );
                }).toList(),
              ),
            ],
            if (config.preferredModes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('偏好互动', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: config.preferredModes.map((m) {
                  final mc = getModeConfig(m);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45B7D1).withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${mc.emoji} ${mc.name}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF45B7D1), fontWeight: FontWeight.w500)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}