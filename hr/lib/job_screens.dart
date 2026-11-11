import 'package:flutter/material.dart';

import 'main.dart';
import 'models.dart';
import 'widgets.dart';
import 'screens.dart';

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key, this.job});
  final Job? job;
  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final form = GlobalKey<FormState>();
  late Job draft;
  bool detailed = true;
  @override
  void initState() {
    super.initState();
    draft = widget.job?.copy() ?? Job(title: '', skills: []);
  }

  Future<void> pickDate(bool expiry) async {
    final date = await showDatePicker(
      context: context,
      initialDate: expiry ? draft.expiry : draft.live,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (date != null && mounted) {
      setState(() {
        if (expiry) {
          draft.expiry = date;
        } else {
          draft.live = date;
        }
      });
    }
  }

  Future<void> addSkill() async {
    String value = '';
    final skill = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          autofocus: true,
          onChanged: (text) => value = text,
          onSubmitted: (text) => Navigator.pop(context, text),
          decoration: const InputDecoration(labelText: 'Skill name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (mounted &&
        skill != null &&
        skill.trim().isNotEmpty &&
        !draft.skills.contains(skill.trim())) {
      setState(() => draft.skills = [...draft.skills, skill.trim()]);
    }
  }

  bool validate() {
    if (!form.currentState!.validate()) return false;
    String? error;
    if (draft.skills.isEmpty) error = 'Add at least one required skill.';
    if (draft.expiry.isBefore(draft.live)) {
      error = 'Expiry date must be on or after the live date.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return false;
    }
    return true;
  }

  void save(bool isDraft) {
    if (isDraft) {
      if (draft.title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a job title to save a draft.')),
        );
        return;
      }
    } else if (!validate()) {
      return;
    }
    draft.draft = isDraft;
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.job == null ? 'Post Job' : 'Edit Job'),
      actions: [
        TextButton(
          onPressed: () => save(true),
          child: const Text('Save Draft'),
        ),
      ],
    ),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          const SizedBox(height: 18),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Detailed Form')),
              ButtonSegment(value: false, label: Text('Quick Form')),
            ],
            selected: {detailed},
            onSelectionChanged: (value) =>
                setState(() => detailed = value.first),
          ),
          const SizedBox(height: 18),
          section('Basic Details', [
            input('Job Title', draft.title, (value) => draft.title = value),
            dropdown('Employment Type *', draft.employment, [
              'Full Time',
              'Part Time',
              'Contract',
              'Internship',
            ], (value) => draft.employment = value),
            AdaptivePair(
              first: dropdown('Experience *', draft.experience, [
                'Fresher',
                '1 - 3 Years',
                '2 - 5 Years',
                '5+ Years',
              ], (value) => draft.experience = value),
              second: input(
                'Salary (CTC)',
                draft.salary,
                (value) => draft.salary = value,
              ),
            ),
            AdaptivePair(
              first: input(
                'Area / Location',
                draft.location,
                (value) => draft.location = value,
              ),
              second: input(
                'Openings',
                draft.openings,
                (value) => draft.openings = value,
                keyboard: TextInputType.number,
              ),
            ),
            if (detailed)
              OutlinedButton.icon(
                onPressed: () => pickDate(false),
                icon: const Icon(Icons.calendar_month),
                label: Text('Live: ${dateLabel(draft.live)}'),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => pickDate(true),
              icon: const Icon(Icons.calendar_month),
              label: Text('Expiry: ${dateLabel(draft.expiry)}'),
            ),
          ]),
          section('Skills Required', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...draft.skills.map(
                  (skill) => InputChip(
                    label: Text(skill),
                    onDeleted: () => setState(
                      () => draft.skills = draft.skills
                          .where((value) => value != skill)
                          .toList(),
                    ),
                  ),
                ),
                ActionChip(
                  label: const Text('+ Add Skill'),
                  onPressed: addSkill,
                ),
              ],
            ),
          ]),
          section('Company Info', [
            input(
              'About Company',
              draft.about,
              (value) => draft.about = value,
              lines: 4,
            ),
          ]),
          section('Role Description', [
            input(
              'Job Description / Role',
              draft.description,
              (value) => draft.description = value,
              lines: 6,
            ),
            if (detailed) ...[
              dropdown('Preferred Qualification *', draft.qualification, [
                'Bachelor’s Degree',
                'Master’s Degree',
                'Diploma',
                'Any qualification',
              ], (value) => draft.qualification = value),
              dropdown('Work Mode *', draft.mode, [
                'On-site',
                'Remote',
                'Hybrid',
              ], (value) => draft.mode = value),
            ],
          ]),
          AdaptivePair(
            first: OutlinedButton(
              onPressed: () {
                if (validate()) {
                  go(
                    context,
                    JobDetailsScreen(job: draft.copy(), preview: true),
                  );
                }
              },
              child: const Text('Preview'),
            ),
            second: primary(
              widget.job == null ? 'Publish Job' : 'Save Job',
              () => save(false),
            ),
          ),
        ],
      ),
    ),
  );
}

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({
    super.key,
    required this.job,
    this.preview = false,
    this.applicants = const [],
    this.onDelete,
  });
  final Job job;
  final bool preview;
  final List<Applicant> applicants;
  final VoidCallback? onDelete;
  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late Job job;
  @override
  void initState() {
    super.initState();
    job = widget.job;
  }

  Future<void> edit() async {
    final result = await Navigator.of(context)
        .push<Job>(MaterialPageRoute(builder: (_) => JobFormScreen(job: job)));
    if (result == null || !mounted) return;
    final original = widget.job;
    original
      ..title = result.title
      ..employment = result.employment
      ..experience = result.experience
      ..salary = result.salary
      ..location = result.location
      ..openings = result.openings
      ..mode = result.mode
      ..qualification = result.qualification
      ..live = result.live
      ..expiry = result.expiry
      ..skills = result.skills
      ..description = result.description
      ..about = result.about
      ..draft = result.draft;
    setState(() => job = original);
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text('Remove “${job.title}” from your jobs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDelete?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicants = widget.applicants
        .where((person) => person.role == job.title)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preview ? 'Job Preview' : 'Job Details'),
      ),
      body: PageBody(
        children: [
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: heading(job.title)),
                    badge(
                      job.draft
                          ? 'Draft'
                          : job.active
                          ? 'Active'
                          : 'Closed',
                    ),
                  ],
                ),
                muted('${job.employment}  ·  ${job.location}'),
                const SizedBox(height: 12),
                muted(
                  'Live: ${dateLabel(job.live)}  |  Expires: ${dateLabel(job.expiry)}',
                ),
              ],
            ),
          ),
          if (!widget.preview)
            TextButton(
              onPressed: () =>
                  go(context, ApplicationsScreen(applicants: applicants)),
              child: Text('Applications (${applicants.length}) →'),
            ),
          section('Details', [
            ...{
              'Experience': job.experience,
              'Salary': job.salary,
              'Openings': job.openings,
              'Work Mode': job.mode,
              'Qualification': job.qualification,
            }.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Flexible(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
            const Divider(),
            const Text(
              'Required Skills',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: job.skills
                  .map((skill) => Chip(label: Text(skill)))
                  .toList(),
            ),
          ]),
          section('Job Description', [
            Text(job.description, style: const TextStyle(height: 1.7)),
          ]),
          section('About Company', [muted(job.about)]),
          if (!widget.preview) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Job Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(job.active ? 'Active' : 'Closed'),
              activeThumbColor: brandBlue,
              value: job.active,
              onChanged: (value) => setState(() => job.active = value),
            ),
            AdaptivePair(
              first: OutlinedButton.icon(
                onPressed: edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Job'),
              ),
              second: TextButton.icon(
                onPressed: delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Job',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ] else
            primary('Back to Form', () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
