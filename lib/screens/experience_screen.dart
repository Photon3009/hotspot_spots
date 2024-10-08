import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hotspot_hosts/model/experience.dart';
import 'package:hotspot_hosts/services/experience_service.dart';
import 'package:hotspot_hosts/widgets/curvy_background.dart';
import 'package:hotspot_hosts/widgets/next_button.dart';
import 'package:hotspot_hosts/widgets/wavy_line_progress.dart';

class ExperienceSelectionScreen extends StatefulWidget {
  const ExperienceSelectionScreen({super.key});

  @override
  _ExperienceSelectionScreenState createState() =>
      _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState extends State<ExperienceSelectionScreen> {
  List<Experience> experiences = [];
  List<int> selectedExperiences = [];
  String description = '';
  bool isLoading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ExperienceService _experienceService = ExperienceService();

  @override
  void initState() {
    super.initState();
    fetchExperiences();
  }

  Future<void> fetchExperiences() async {
    try {
      final fetchedExperiences = await _experienceService.fetchExperiences();
      setState(() {
        experiences = fetchedExperiences;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error: $e');
    }
  }

  void _onTap(int index) {
    if (selectedExperiences.contains(experiences[index].id)) {
      // Deselecting an experience
      setState(() {
        selectedExperiences.remove(experiences[index].id);
      });
      _listKey.currentState!.removeItem(index, (context, animation) {
        return FadeTransition(
          opacity: animation,
          child: ExperienceCard(
            experience: experiences[index],
            isSelected: false,
            onTap: () {},
          ),
        );
      });
    } else {
      // Selecting an experience
      setState(() {
        selectedExperiences.add(experiences[index].id);
        // Remove and reinsert the selected experience at the top
        Experience selectedExperience = experiences.removeAt(index);
        experiences.insert(0, selectedExperience);
      });
      _listKey.currentState!.insertItem(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 2.0,
              colors: [
                Colors.grey[700]!,
                Colors.grey[900]!,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CustomPaint(
          size: const Size(double.infinity, 50),
          painter:
              WavyLinePainter(currentPage: 1, totalPages: 2, waveWidth: 10),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CurvyBackground(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      '01',
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: Colors.grey,
                          fontSize: 15),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'What kind of experiences do you want to host?',
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: AnimatedList(
                      key: _listKey,
                      scrollDirection: Axis.horizontal,
                      initialItemCount: experiences.length,
                      itemBuilder: (context, index, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ExperienceCard(
                              experience: experiences[index],
                              isSelected: selectedExperiences
                                  .contains(experiences[index].id),
                              onTap: () => _onTap(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Describe your perfect hotspot',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'SpaceGrotesk',
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF9196FF)),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      maxLines: 3,
                      maxLength: 250,
                      onChanged: (value) {
                        setState(() {
                          description = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: NextButton(
                      isActive: selectedExperiences.isNotEmpty,
                      onPressed: () {
                        debugPrint(
                            'Selected experiences: $selectedExperiences');
                        debugPrint('Description: $description');
                        Navigator.of(context).pushNamed('/onboarding');
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ExperienceCard extends StatefulWidget {
  final Experience experience;
  final bool isSelected;
  final VoidCallback onTap;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _ExperienceCardState createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  late double rotationAngle;

  @override
  void initState() {
    super.initState();
    rotationAngle = Random().nextBool()
        ? Random().nextDouble() * 0.1
        : Random().nextDouble() * -0.1;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 120,
          height: 120,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ColorFiltered(
                colorFilter: widget.isSelected
                    ? const ColorFilter.mode(
                        Colors.transparent, BlendMode.multiply)
                    : const ColorFilter.mode(
                        Colors.black, BlendMode.saturation),
                child: Image.network(
                  widget.experience.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
