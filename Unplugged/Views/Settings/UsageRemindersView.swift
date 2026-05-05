import SwiftUI
import UserNotifications

struct UsageRemindersView: View {
    @State private var reminders: [ReminderItem] = []
    @State private var showAddSheet   = false
    @State private var permissionDenied = false

    var body: some View {
        List {
            if reminders.isEmpty {
                emptyState
            } else {
                remindersSection
            }
            infoSection
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { checkPermissionThenAdd() } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add reminder")
            }
        }
        .onAppear { reminders = ReminderItem.loadAll() }
        .sheet(isPresented: $showAddSheet) {
            AddReminderSheet { newItem in
                reminders.append(newItem)
                ReminderItem.saveAll(reminders)
                NotificationService.shared.scheduleTimeOfDayReminder(newItem)
            }
        }
        .alert("Notifications Disabled", isPresented: $permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to use reminders.")
        }
    }

    private var emptyState: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No reminders set")
                    .font(.headline)
                Text("Tap + to add a daily reminder at a time that works for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .listRowBackground(Color.clear)
    }

    private var remindersSection: some View {
        Section("Your Reminders") {
            ForEach(reminders) { item in
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color(hex: "#4CAF50"))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.displayTime)
                            .font(.subheadline.bold())
                        if !item.label.isEmpty {
                            Text(item.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: deleteReminders)
        }
    }

    private var infoSection: some View {
        Section {
            Label("Reminders repeat daily at the set time.", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .listRowBackground(Color.clear)
    }

    private func checkPermissionThenAdd() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            await MainActor.run {
                if settings.authorizationStatus == .denied {
                    permissionDenied = true
                } else {
                    showAddSheet = true
                }
            }
        }
    }

    private func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            NotificationService.shared.cancelReminder(id: reminders[index].notificationID)
        }
        reminders.remove(atOffsets: offsets)
        ReminderItem.saveAll(reminders)
    }
}

// MARK: - Add Reminder Sheet

private struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (ReminderItem) -> Void

    @State private var selectedTime = Date()
    @State private var label = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Reminder time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Label (optional)") {
                    TextField("e.g. Morning check-in", text: $label)
                        .textInputAutocapitalization(.sentences)
                }

                Section {
                    Text("This reminder will fire every day at the selected time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let cal = Calendar.current
                        let hour   = cal.component(.hour, from: selectedTime)
                        let minute = cal.component(.minute, from: selectedTime)
                        let item   = ReminderItem(label: label, hour: hour, minute: minute)
                        onSave(item)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack { UsageRemindersView() }
}
