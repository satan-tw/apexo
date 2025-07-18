import 'package:apexo/app/routes.dart';
import 'package:apexo/common_widgets/apexo_field.dart';
import 'package:apexo/common_widgets/appointments_list_footer.dart';
import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:apexo/services/archived.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/common_widgets/appointment_card.dart';
import 'package:apexo/common_widgets/tag_input.dart';
import 'package:apexo/services/login.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/features/doctors/doctor_model.dart';
import 'package:apexo/services/network.dart';
import 'package:apexo/services/users.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Colors;
import 'package:form_validator/form_validator.dart';

final GlobalKey<FormState> _key = GlobalKey<FormState>();

void openDoctor([Doctor? doctor]) {
  final editingCopy = Doctor.fromJson(doctor?.toJson() ?? {});

  routes.openPanel(Panel(
    key: _key,
    item: editingCopy,
    store: doctors,
    icon: FluentIcons.medical,
    title: doctors.get(editingCopy.id) == null
        ? txt("newDoctor")
        : editingCopy.title,
    tabs: [
      PanelTab(
        title: txt("doctorDetails"),
        icon: FluentIcons.medical,
        body: _DoctorDetails(editingCopy),
      ),
      PanelTab(
        title: txt("upcomingAppointments"),
        icon: FluentIcons.calendar_reply,
        body: _UpcomingAppointments(editingCopy),
        onlyIfSaved: true,
        padding: 0,
        footer: AppointmentsListFooter(forDoctorID: editingCopy.id),
      )
    ],
  ));
}

class _DoctorDetails extends StatelessWidget {
  final Doctor doctor;

  const _DoctorDetails(this.doctor);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _key,
      child: Column(
        children: [
          InfoLabel(
            label: "${txt("doctorName")}:",
            child: ApexoField(
              key: WK.fieldDoctorName,
              controller: TextEditingController(text: doctor.title),
              placeHolder: "${txt("doctorName")}...",
              validator: ValidationBuilder().required().build(),
              onChanged: (val) {
                doctor.title = val;
              },
            ),
          ),
          InfoLabel(
            label: "${txt("doctorEmail")}:",
            child: ApexoField(
              key: WK.fieldDoctorEmail,
              controller: TextEditingController(text: doctor.email),
              placeHolder: "${txt("doctorEmail")}...",
              validator: ValidationBuilder().required().build(),
              onChanged: (val) {
                doctor.email = val;
              },
            ),
          ),
          InfoLabel(
            label: "${txt("dutyDays")}:",
            child: TagInputWidget(
              key: WK.fieldDutyDays,
              suggestions: [
                ...allDays.map((e) => TagInputItem(value: e, label: txt(e)))
              ],
              onChanged: (data) {
                doctor.dutyDays = data
                    .map((e) => e.value ?? "")
                    .where((e) => e.isNotEmpty)
                    .toList();
              },
              initialValue: [
                ...doctor.dutyDays
                    .map((e) => TagInputItem(value: e, label: txt(e)))
              ],
              strict: true,
              limit: 7,
            ),
          ),
          if (login.isAdmin && network.isOnline())
            InfoLabel(
              label: "${txt("lockToUsers")}:",
              child: TagInputWidget(
                suggestions: [
                  ...users.list().map(
                      (e) => TagInputItem(value: e.id, label: e.data["email"]))
                ],
                onChanged: (data) {
                  doctor.lockToUserIDs = data
                      .map((e) => e.value ?? "")
                      .where((e) => e.isNotEmpty)
                      .toList();
                },
                initialValue: [
                  ...doctor.lockToUserIDs.map((e) => TagInputItem(
                      value: e,
                      label: users
                              .list()
                              .where((u) => u.id == e)
                              .firstOrNull
                              ?.data["email"] ??
                          "NOT FOUND: $e")),
                ],
                strict: true,
                limit: 9999,
              ),
            ),
        ].map((e) => [e, const SizedBox(height: 10)]).expand((e) => e).toList(),
      ),
    );
  }
}

class _UpcomingAppointments extends StatelessWidget {
  final Doctor doctor;

  const _UpcomingAppointments(this.doctor);

  @override
  Widget build(BuildContext context) {
    return MStreamBuilder(
        streams: [appointments.observableMap.stream, showArchived.stream],
        builder: (context, snapshot) {
          return doctor.upcomingAppointments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InfoBar(
                        title: Txt(txt("noUpcomingAppointmentsForThisDoctor"))),
                  ),
                )
              : Column(
                  children: [
                    ...List.generate(doctor.upcomingAppointments.length,
                        (index) {
                      final appointment = doctor.upcomingAppointments[index];
                      String? difference;
                      if (doctor.upcomingAppointments.last != appointment) {
                        int differenceInDays = appointment.date
                            .difference(
                                doctor.upcomingAppointments[index + 1].date)
                            .inDays
                            .abs();

                        difference =
                            "after $differenceInDays day${differenceInDays > 1 ? "s" : ""}";
                      }
                      return AppointmentCard(
                        key: Key(appointment.id),
                        appointment: appointment,
                        difference: difference,
                        hide: const [AppointmentSections.doctors],
                        number: index + 1,
                      );
                    })
                  ],
                );
        });
  }
}
