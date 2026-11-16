import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

String chatError(Object? error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Chat access is unavailable. Check your account and contact support.',
      'unavailable' => 'Unable to connect. Check your internet connection.',
      'failed-precondition' => 'Chat is not ready. Please contact support.',
      _ => 'Unable to load chat. Please try again.',
    };
  }
  return 'Unable to load chat. Please try again.';
}

class CareerChatInbox extends StatelessWidget {
  const CareerChatInbox({super.key});
  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const Center(child: Text('Sign in to view your messages.'));
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, auth) {
        final user = auth.data;
        if (user == null)
          return const Center(child: Text('Sign in to view your messages.'));
        return _Inbox(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class _Inbox extends StatefulWidget {
  const _Inbox({super.key, required this.uid});
  final String uid;
  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _rooms = _listen();
  Stream<QuerySnapshot<Map<String, dynamic>>> _listen() => FirebaseFirestore
      .instance
      .collection('career_chats')
      .where('participantIds', arrayContains: widget.uid)
      .snapshots();
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _rooms,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return _Retry(
          message: chatError(snapshot.error),
          retry: () => setState(() => _rooms = _listen()),
        );
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final rooms = snapshot.data!.docs.toList()
        ..sort(
          (a, b) =>
              ((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0)
                  .compareTo(
                    (a.data()['createdAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0,
                  ),
        );
      if (rooms.isEmpty)
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No conversations yet. Chat becomes available after an application is submitted.',
            ),
          ),
        );
      return ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final data = room.data();
          final applicant = data['employeeUid'] as String? ?? '';
          final label = applicant == widget.uid
              ? '${data['company']} recruitment team'
              : 'Applicant ${applicant.length > 6 ? applicant.substring(0, 6) : applicant}';
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
            title: Text(label),
            subtitle: Text('${data['jobTitle']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CareerConversation(
                  chatId: room.id,
                  title: '${data['jobTitle']}',
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class CareerConversation extends StatefulWidget {
  const CareerConversation({
    super.key,
    required this.chatId,
    required this.title,
  });
  final String chatId, title;
  @override
  State<CareerConversation> createState() => _CareerConversationState();
}

class _CareerConversationState extends State<CareerConversation> {
  final _draft = TextEditingController();
  bool _sending = false;
  late final String? _accountUid = FirebaseAuth.instance.currentUser?.uid;
  int _limit = 50;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _messages = _listen();
  CollectionReference<Map<String, dynamic>> get _collection => FirebaseFirestore
      .instance
      .collection('career_chats')
      .doc(widget.chatId)
      .collection('messages');
  Stream<QuerySnapshot<Map<String, dynamic>>> _listen() => _collection
      .orderBy('createdAt', descending: true)
      .limit(_limit)
      .snapshots(includeMetadataChanges: true);
  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_sending || text.isEmpty || uid == null || uid != _accountUid) return;
    if (text.length > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please shorten your message to 4000 characters.'),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _collection.add({
        'senderId': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _draft.clear();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(chatError(error))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, auth) {
        if (auth.data == null || auth.data!.uid != _accountUid)
          return const Center(
            child: Text('Sign in to continue this conversation.'),
          );
        return Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messages,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return _Retry(
                      message: chatError(snapshot.error),
                      retry: () => setState(() => _messages = _listen()),
                    );
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;
                  if (messages.isEmpty)
                    return const Center(
                      child: Text(
                        'Start the conversation about this application.',
                      ),
                    );
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length)
                        return messages.length < _limit
                            ? const SizedBox.shrink()
                            : TextButton(
                                onPressed: () => setState(() {
                                  _limit += 50;
                                  _messages = _listen();
                                }),
                                child: const Text('Load earlier messages'),
                              );
                      final message = messages[index];
                      final data = message.data();
                      final mine = data['senderId'] == auth.data!.uid;
                      final time = (data['createdAt'] as Timestamp?)
                          ?.toDate()
                          .toLocal();
                      final stamp = time == null
                          ? 'Sending...'
                          : '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 360),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: mine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['text'] as String? ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                message.metadata.hasPendingWrites
                                    ? 'Sending...'
                                    : stamp,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _draft,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 4000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Send message',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(message)),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
}
