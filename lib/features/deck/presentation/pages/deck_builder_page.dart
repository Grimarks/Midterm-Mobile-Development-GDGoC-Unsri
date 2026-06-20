import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/core/constants/app_constants.dart';
import 'package:focusdeck/core/widgets/app_button.dart';
import 'package:focusdeck/core/widgets/app_text_field.dart';
import 'package:focusdeck/features/deck/data/deck_model.dart';
import 'package:focusdeck/features/deck/providers/deck_provider.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

const _uuid = Uuid();

class DeckBuilderPage extends ConsumerStatefulWidget {
  final String? deckId;
  const DeckBuilderPage({super.key, this.deckId});

  @override
  ConsumerState<DeckBuilderPage> createState() => _DeckBuilderPageState();
}

class _DeckBuilderPageState extends ConsumerState<DeckBuilderPage> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<FocusCard> _cards = [];
  int _selectedColorIndex = 0;
  bool _loading = false;
  bool _initialized = false;

  bool get isEditing => widget.deckId != null;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initDeck() async {
    if (_initialized || !isEditing) {
      _initialized = true;
      return;
    }
    _initialized = true;
    final deck =
        await ref.read(deckServiceProvider).getDeck(widget.deckId!);
    if (deck != null && mounted) {
      setState(() {
        _titleController.text = deck.title;
        _cards = List.from(deck.cards);
        _selectedColorIndex = deck.colorIndex;
      });
    }
  }

  void _addCard() {
    if (_cards.length >= AppConstants.maxCardsPerDeck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 cards per deck.')),
      );
      return;
    }
    _showCardDialog();
  }

  void _showCardDialog({FocusCard? existing, int? index}) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final noteCtrl =
        TextEditingController(text: existing?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existing != null ? 'Edit card' : 'New focus card',
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: titleCtrl,
                label: 'What do you want to focus on?',
                hint: 'e.g. Complete chapter 3 of thesis',
                maxLength: AppConstants.maxCardTitleLength,
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: noteCtrl,
                label: 'Note (optional)',
                hint: 'Any context or reminder...',
                maxLines: 2,
                maxLength: AppConstants.maxCardNoteLength,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final card = FocusCard(
                          id: existing?.id ?? _uuid.v4(),
                          title: titleCtrl.text.trim(),
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                        setState(() {
                          if (index != null) {
                            _cards[index] = card;
                          } else {
                            _cards.add(card);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(existing != null ? 'Save' : 'Add card'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one focus card.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      if (isEditing) {
        final existing =
            await ref.read(deckServiceProvider).getDeck(widget.deckId!);
        if (existing != null) {
          final updated = existing.copyWith(
            title: _titleController.text.trim(),
            cards: _cards,
            colorIndex: _selectedColorIndex,
          );
          await ref.read(deckServiceProvider).updateDeck(updated);
        }
      } else {
        await ref.read(deckServiceProvider).createDeck(
              uid: user.uid,
              title: _titleController.text.trim(),
              cards: _cards,
              colorIndex: _selectedColorIndex,
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initDeck(),
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textSecondary),
            ),
            title: Text(isEditing ? 'Edit deck' : 'New deck'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AppButton(
                  label: isEditing ? 'Save' : 'Create',
                  onPressed: _save,
                  loading: _loading,
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deck title
                  Text(
                    'DECK NAME',
                    style: Theme.of(context).textTheme.labelLarge,
                  ).animate().fadeIn(),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _titleController,
                    label: 'Name',
                    hint: 'e.g. Morning deep work',
                    maxLength: AppConstants.maxDeckTitleLength,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Deck name is required';
                      }
                      return null;
                    },
                  ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // Color picker
                  Text(
                    'DECK COLOR',
                    style: Theme.of(context).textTheme.labelLarge,
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      AppColors.cardColors.length,
                      (i) => GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.cardColors[i],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedColorIndex == i
                                  ? AppColors.cardAccents[i]
                                  : AppColors.border,
                              width: _selectedColorIndex == i ? 2 : 1,
                            ),
                          ),
                          child: _selectedColorIndex == i
                              ? Icon(Icons.check_rounded,
                                  color: AppColors.cardAccents[i],
                                  size: 16)
                              : null,
                        ),
                      ),
                    ),
                  ).animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 32),

                  // Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FOCUS CARDS',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '${_cards.length}/${AppConstants.maxCardsPerDeck}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 4),

                  Text(
                    'What are you committing to focus on this session?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate(delay: 220.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // Card list
                  ..._cards.asMap().entries.map((entry) {
                    final i = entry.key;
                    final card = entry.value;
                    return _CardItem(
                      card: card,
                      index: i,
                      accentColor: AppColors.cardAccents[
                          _selectedColorIndex % AppColors.cardAccents.length],
                      onEdit: () => _showCardDialog(existing: card, index: i),
                      onDelete: () =>
                          setState(() => _cards.removeAt(i)),
                    ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn().slideY(begin: 0.1);
                  }),

                  if (_cards.length < AppConstants.maxCardsPerDeck)
                    GestureDetector(
                      onTap: _addCard,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: AppColors.textMuted, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Add focus card',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardItem extends StatelessWidget {
  final FocusCard card;
  final int index;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardItem({
    required this.card,
    required this.index,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (card.note != null && card.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    card.note!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_rounded,
                      color: AppColors.textMuted, size: 16),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
