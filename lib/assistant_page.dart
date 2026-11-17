import 'package:flutter/material.dart';

import 'assistant.dart';
import 'data.dart';
import 'ui.dart';

class _Msg {
  final String text;
  final bool mine;
  _Msg(this.text, this.mine);
}

class AssistantPage extends StatefulWidget {
  final SalesData data;
  const AssistantPage({super.key, required this.data});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  late final Assistant bot = Assistant(widget.data);
  final TextEditingController ctrl = TextEditingController();
  final ScrollController scroll = ScrollController();
  final List<_Msg> msgs = [
    _Msg('Bonjour, je suis votre assistant décisionnel. Posez-moi une question sur les ventes, les marges, les objectifs ou les prévisions.', false),
  ];

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      msgs.add(_Msg(t, true));
      msgs.add(_Msg(bot.answer(t), false));
    });
    ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PageHeader(
                title: 'Assistant décisionnel',
                subtitle: 'Posez vos questions en français sur les ventes, marges, objectifs et prévisions',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: msgs.length,
              itemBuilder: (context, i) {
                final m = msgs[i];
                return Align(
                  alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: m.mine
                        ? BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(16))
                        : panelDecoration(context),
                    child: Text(
                      m.text,
                      style: TextStyle(color: m.mine ? cs.onPrimary : cs.onSurface, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final s in Assistant.suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Posez une question…',
                      filled: true,
                      fillColor: panelColorOf(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: () => _send(ctrl.text), icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
