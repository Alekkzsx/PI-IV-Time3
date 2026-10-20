import 'package:flutter/material.dart';

class StudentCalendarPage extends StatelessWidget {
  const StudentCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área Esquerda: Calendário Principal
          Expanded(flex: 3, child: _buildMainCalendar()),
          const SizedBox(width: 24),
          // Área Direita: Sidebar (Mini calendário e Filtros)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildMiniCalendar(),
                const SizedBox(height: 24),
                _buildFiltersCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CALENDÁRIO PRINCIPAL
  // ==========================================
  Widget _buildMainCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildMainCalendarHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildDaysOfWeek(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMainCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Hoje',
                  style: TextStyle(color: Color(0xFF18181B)),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_left, size: 20),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE5E7EB),
                    ),
                    InkWell(
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_right, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const Text(
                'SETEMBRO 2026',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Semana', false),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE5E7EB),
                    ),
                    _buildToggleButton('Mês', true),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE5E7EB),
                    ),
                    _buildToggleButton('Agenda', false),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isActive ? const Color(0xFF3F3F46) : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : const Color(0xFF52525B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    return Row(
      children: days
          .map(
            (day) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF52525B),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    // Montando a grade estática conforme o protótipo
    return Column(
      children: [
        _buildCalendarRow([
          _buildCell('30', isOtherMonth: true),
          _buildCell('31', isOtherMonth: true),
          _buildCell('1'),
          _buildCell('2'),
          _buildCell('3'),
          _buildCell('4'),
          _buildCell('5'),
        ]),
        _buildCalendarRow([
          _buildCell('6'),
          _buildCell('7'),
          _buildCell('8'),
          _buildCell('9'),
          _buildCell('10'),
          _buildCell('11'),
          _buildCell('12'),
        ]),
        _buildCalendarRow([
          _buildCell('13'),
          _buildCell('14'),
          _buildCell('15'),
          _buildCell('16'),
          _buildCell('17'),
          _buildCell('18'),
          _buildCell('19'),
        ]),
        _buildCalendarRow([
          _buildCell(
            '20',
            isSelected: true,
            events: [
              _buildEventPill('23:59 Entreg...', const Color(0xFF10B981)),
              _buildEventPill('19:00 Aula A...', const Color(0xFF10B981)),
            ],
          ),
          _buildCell(
            '21',
            events: [
              _buildEventPill('18:00 Fórum ...', const Color(0xFFF59E0B)),
            ],
          ),
          _buildCell(
            '22',
            events: [
              _buildEventPill('19:00 Aula R...', const Color(0xFFEF4444)),
            ],
          ),
          _buildCell('23'),
          _buildCell(
            '24',
            events: [
              _buildEventPill('23:59 Ativid...', const Color(0xFF8B5CF6)),
            ],
          ),
          _buildCell(
            '25',
            events: [
              _buildEventPill('20:40 Labor...', const Color(0xFF3B82F6)),
            ],
          ),
          _buildCell('26'),
        ]),
        _buildCalendarRow([
          _buildCell('27'),
          _buildCell('28'),
          _buildCell(
            '29',
            events: [
              _buildEventPill('20:40 Avalia...', const Color(0xFFEF4444)),
            ],
          ),
          _buildCell('30'),
          _buildCell('1', isOtherMonth: true),
          _buildCell('2', isOtherMonth: true),
          _buildCell('3', isOtherMonth: true),
        ], isLastRow: true),
      ],
    );
  }

  Widget _buildCalendarRow(List<Widget> cells, {bool isLastRow = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cells.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget cell = entry.value;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: const Color(0xFFE5E7EB),
                    width: idx < 6 ? 1 : 0,
                  ),
                  bottom: BorderSide(
                    color: const Color(0xFFE5E7EB),
                    width: isLastRow ? 0 : 1,
                  ),
                ),
              ),
              child: cell,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCell(
    String day, {
    bool isOtherMonth = false,
    bool isSelected = false,
    List<Widget>? events,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isOtherMonth
                          ? const Color(0xFFA1A1AA)
                          : const Color(0xFF18181B)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (events != null) ...events,
        ],
      ),
    );
  }

  Widget _buildEventPill(String title, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, color: Color(0xFF52525B)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ==========================================
  // SIDEBAR (DIREITA)
  // ==========================================
  Widget _buildMiniCalendar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.chevron_left, size: 16),
              Text(
                'SETEMBRO 2026',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.chevron_right, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          _buildMiniCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarGrid() {
    final days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days
              .map(
                (d) => SizedBox(
                  width: 24,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _buildMiniRow(
          ['30', '31', '1', '2', '3', '4', '5'],
          isFaded: [true, true, false, false, false, false, false],
        ),
        _buildMiniRow(['6', '7', '8', '9', '10', '11', '12']),
        _buildMiniRow(['13', '14', '15', '16', '17', '18', '19']),
        _buildMiniRow([
          '20',
          '21',
          '22',
          '23',
          '24',
          '25',
          '26',
        ], selectedIdx: 0),
        _buildMiniRow(
          ['27', '28', '29', '30', '1', '2', '3'],
          isFaded: [false, false, false, false, true, true, true],
        ),
      ],
    );
  }

  Widget _buildMiniRow(
    List<String> dates, {
    List<bool>? isFaded,
    int? selectedIdx,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dates.asMap().entries.map((entry) {
          int idx = entry.key;
          String date = entry.value;
          bool faded = isFaded != null ? isFaded[idx] : false;
          bool selected = selectedIdx == idx;

          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Colors.white
                    : (faded
                          ? const Color(0xFFD4D4D8)
                          : const Color(0xFF18181B)),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.keyboard_arrow_down, size: 16),
              SizedBox(width: 8),
              Text(
                'CALENDÁRIOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterCheckbox('ALEX GABRIEL SOARES SOUSA'),
          _buildFilterCheckbox(
            '218131 - ANÁLISE E PROJETO DE SISTEMAS II (MAT) 0103-04-26-2s',
          ),
          _buildFilterCheckbox(
            '218131 - ESTUDOS DE BANCO DE DADOS II (MAT) 0103-04-26-2s',
          ),
          _buildFilterCheckbox(
            '218131 - FILOSOFIA, INFORMAÇÃO E SOCIEDADE (MAT) 0103-04-26-2s',
          ),
          _buildFilterCheckbox('218131 - FUNDAMENTOS DE SISTEMAS OPERACIONAIS'),
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.keyboard_arrow_right, size: 16),
              SizedBox(width: 8),
              Text(
                'SEM DATA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'Feed do calendário',
                style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCheckbox(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, color: Color(0xFF52525B)),
            ),
          ),
          const Icon(Icons.more_vert, size: 14, color: Color(0xFFA1A1AA)),
        ],
      ),
    );
  }
}
