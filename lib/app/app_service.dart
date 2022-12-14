import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tedangle/app/modules/chat/models/message.dart';

class AppService extends GetxController {
  final _supabase = Supabase.instance.client;
  final _password = 'Tedangle@supabase';

  RxString appName = RxString('Tedangle');
  @override
  void onInit() {
    super.onInit();
  }

  Future<void> _createUser(int i) async {
    final response = await _supabase.auth.signUp('test$i@test.com', _password);
    await _supabase.from('contact').insert({
      'id': response.user!.id,
      'username': 'User $i',
    }).execute();
  }

  Future<void> createUsers() async {
    await _createUser(1);
    await _createUser(2);
  }

  Future<void> signIn(int i) async {
    await _supabase.auth.signIn(email: 'test$i@test.com', password: _password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<String> _getUserTo() async {
    final response = await _supabase
        .from('contact')
        .select('id')
        .not('id', 'eq', getCurrentUserId())
        .execute();

    return response.data[0]['id'];
  }

  Future<void> markAsRead(String messageId) async {
    await _supabase
        .from('message')
        .update({'mark_as_read': true})
        .eq('id', messageId)
        .execute();
  }

  Stream<List<Message>> getMessages() {
    return _supabase
        .from('message')
        .stream(['id'])
        .order('created_at')
        .execute()
        .map((maps) => maps
            .map((item) => Message.fromJson(item, getCurrentUserId()))
            .toList());
  }

  Future<void> saveMessage(String content) async {
    final userTo = await _getUserTo();
    final message = Message.create(
      content: content,
      userFrom: getCurrentUserId(),
      userTo: userTo,
    );
    await _supabase.from('message').insert(message.toMap()).execute();
  }

  bool isAuthenticated() => _supabase.auth.currentUser != null;

  String getCurrentUserId() =>
      isAuthenticated() ? _supabase.auth.currentUser!.id : '';

  String getCurrentUserEmail() =>
      isAuthenticated() ? _supabase.auth.currentUser!.email ?? '' : '';
}
