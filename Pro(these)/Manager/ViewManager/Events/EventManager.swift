//
//  EventViewManager.swift
//  Pro(these)
//
//  Created by Frederik Kohler on 02.05.23.
//

import SwiftUI
import CoreData
import EventKit
import ContactsUI

class EventManager: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    @Published var loadContact = false
    @Published var selectedContact: CNContact?
    
    @Published var contacts: [Contact] = []
    @Published var events: [Event] = []
    
    var eventsNextWeek: [Event] {
        events.filter { $0.startDate ?? Date() > Date.now && $0.startDate ?? Date() < Date.now.sevenDaysOut }
    }
    
    var eventsnextmonth: [Event] {
        events.filter { $0.startDate ?? Date() > Date.now.sevenDaysOut && $0.startDate ?? Date() < Date.now.thirtyDaysOut }
    }
    
    var eventsPast: [Event] {
        events.filter{ $0.startDate ?? Date() < Date.now }
    }
    
    var eventsAll: [Event] {
        events.filter{ $0.startDate ?? Date() > Date.now }
    }
    
    @Published var showCal = false
    
    // sheets
    @Published var isAddContactSheet: Bool = false
    @Published var isAddEventSheet: Bool = false

    @Published var editContact: Contact?
    @Published var editEvent: Event?
    
    @Published var addEventIcon = "bandage.fill"
    @Published var addEventStarDate = Date()
    @Published var addEventEndDate = Date()
    @Published var addEventContact: Contact?
    @Published var addEventContactPerson: ContactPerson?
    @Published var addEventTitel = ""
    @Published var sendEventNotofication = true
    @Published var addEventAlarm = -86400 //  86400
    
    /// Contact
    @Published var addContactName = ""
    @Published var addContactPhone = ""
    @Published var addContactEmail = ""
    @Published var addContactEventTitel = ""
    @Published var addContactIcon: String = "person.crop.circle.badge.xmark"
    @Published var addContactTitel: String = "Others"
    
    @Published var isthisWeekExpand = true
    @Published var isthisMonthExpand = true
    @Published var isPastExpand = false
    @Published var isContactExpand = true
    
    @Published var error: LocalizedStringKey = ""
    
    @Published var contactTypes = [
        ( type: "Hospital", name: LocalizedStringKey("Hospital"), icon: "bandage.fill" , image: "Hospital"),
        ( type: "Specialist Clinic", name: LocalizedStringKey("Specialist Clinic"), icon: "bandage.fill" , image: "Hospital"),
        ( type: "family doctor", name: LocalizedStringKey("family doctor"), icon: "bandage.fill" , image: "Doctor"),
        ( type: "orthopedist", name: LocalizedStringKey("orthopedist"), icon: "bandage.fill" , image: "Doctor"),
        ( type: "Health insurance", name: LocalizedStringKey("Health insurance"), icon: "bolt.heart.fill" , image: "Illustration"),
        ( type: "Medical supply store", name: LocalizedStringKey("Medical supply store"), icon: "figure.roll" , image: "Physio"),
        ( type: "Physiotherapist", name: LocalizedStringKey("Physiotherapist"), icon: "figure.run" , image: "Physio"),
        ( type: "Psychiatrist", name: LocalizedStringKey("Psychiatrist"), icon: "brain.head.profile" , image: "Doctor"),
        ( type: "Psychologist", name: LocalizedStringKey("Psychologist"), icon: "brain.head.profile" , image: "Doctor"),
        ( type: "Others", name: LocalizedStringKey("Others"), icon: "questionmark.app.dashed" , image: "Illustration"),
    ]
    
    @Published var alarms = [ 
        (type: "10 minutes before", text: LocalizedStringKey("10 minutes before"), notification: -86400, ekAlarm: -600 ),     // N: 1t    K: 10min
        (type: "30 minutes before", text: LocalizedStringKey("30 minutes before"), notification: -86400, ekAlarm: -1800 ),    // N: 1t    K: 30min
        (type: "1 hours before", text: LocalizedStringKey("1 hours before"), notification: -86400, ekAlarm: -3600 ),      // N: 1t    K: 1h
        (type: "2 hours before", text: LocalizedStringKey("2 hours before"), notification: -86400, ekAlarm: -7200 ),     // N: 1t    K: 2h
        (type: "1 day before", text: LocalizedStringKey("1 day before"), notification: -172800, ekAlarm: -86400 ),       // N: 2t    K: 1t
        (type: "2 days before", text: LocalizedStringKey("2 days before"), notification: -259200, ekAlarm: -172800 ),     // N: 3t    K: 2t
        (type: "3 days before", text: LocalizedStringKey("3 days before"), notification: -345600, ekAlarm: -259200 )      // N: 4t    K: 3t
    ]
    
    func addContact(){
        //name: String, icon: String, titel: String, phone: String, mail: String
        let newContact = Contact(context: PersistenceController.shared.container.viewContext)
        newContact.name = addContactName
        newContact.phone = addContactPhone
        newContact.mail = addContactEmail
        newContact.icon = addContactIcon
        newContact.titel = addContactTitel
        contacts.append(newContact)
        do {
            try PersistenceController.shared.container.viewContext.save()
            self.isAddContactSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.addContactIcon = ""
                self.addContactName = ""
                self.addContactPhone = ""
                self.addContactEmail = ""
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
      
    }
    
    func editContact(_ contact: Contact, completion: @escaping (_ success: Bool) -> Void ){
        
        contact.name = self.addContactName
        contact.phone = self.addContactPhone
        contact.mail = self.addContactEmail
        contact.icon = self.addContactIcon
        contact.titel = self.addContactTitel
        
        do {
            try PersistenceController.shared.container.viewContext.save()
            
            completion(true)
            
            self.addContactIcon = ""
            self.addContactName = ""
            self.addContactPhone = ""
            self.addContactEmail = ""
            self.addContactTitel = ""
        } catch {
            let nsError = error as NSError
            completion(false)
            fatalError("cant update contact \(nsError), \(nsError.userInfo)")
            
        }
    }
    
    func generateNewEventDates(date: Date) -> (start: Date, end: Date) {
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        return (start: Calendar.current.date(byAdding: .hour, value: 0, to: newDate)!, end: Calendar.current.date(byAdding: .hour, value: 1, to: newDate)!)
    }
    
    func openAddEventSheet(date: Date) {
        self.editEvent = nil
        let newEventDate = self.generateNewEventDates(date: date)
        self.addEventStarDate = newEventDate.start
        self.addEventEndDate = newEventDate.end
        self.isAddEventSheet.toggle()
    }
    
    func addEvent(){
        guard addEventTitel != "" else {
            return error = LocalizedStringKey("Please enter an appointment description!")
        }
        
        guard addEventContact != nil else {
            return error = LocalizedStringKey("Please provide a contact!")
        }
        
        let newEvent = Event(context: viewContext)
        newEvent.eventID = UUID().uuidString
        newEvent.titel = addEventTitel
        newEvent.icon = addEventIcon
        newEvent.startDate = addEventStarDate
        newEvent.endDate = addEventEndDate
        newEvent.tasks = nil
        newEvent.contact = addEventContact
        
        if let contact = addEventContact {
            newEvent.contact = contact
            contact.addToEvents(newEvent)
        }

        
        if let contact = addEventContact,
           let contactPersonsSet = contact.contactPersons as? Set<ContactPerson>,
           let firstContactPerson = contactPersonsSet.first {
            newEvent.contactPerson = firstContactPerson
            firstContactPerson.addToEvent(newEvent)
        }

        let alarm:Int?
        if sendEventNotofication == true {
            alarm = addEventAlarm
        } else {
            alarm = 0
        }
        
        do {
            FK_EventProvider.shared.insertEvent(store: EKEventStore(), event: newEvent, alarm: alarm!, completionHandler: { res in
                newEvent.eventID = res
                events.append(newEvent)
            })
            try PersistenceController.shared.container.viewContext.save()
            if let unwrapped = addEventContact?.name! {
                guard !sendEventNotofication else {                    
                    let loc = NSLocalizedString("You have an appointment at %@ on %@ at %@ ✌️. Come by and have a look at your notes. 😉", comment: "")

                    PushNotificationManager().PushNotificationByAddEvent2(
                        identifier: newEvent.eventID!,
                        title: AppConfig().AppName,
                        body: String(format: loc, String(describing: unwrapped), convertDateToNotoficationString(addEventStarDate).date, convertDateToNotoficationString(addEventStarDate).time ),
                        triggerDate: Calendar.current.date(byAdding: .second, value: alarms.first(where: { $0.ekAlarm == self.addEventAlarm })!.notification, to: addEventStarDate)!,
                        repeater: false)
                    
                    return
                }
            }
            
            self.addEventTitel = ""
            self.addEventIcon = "bandage.fill"
            self.addEventStarDate = Date()
            self.addEventEndDate = Date()
            self.addEventContact = nil
            self.error = ""
            //fetchContacts()
            self.isAddEventSheet = false
           
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
   // asdsad
    func saveEditEvent(_ event: Event, completion: @escaping (_ success: Bool) -> Void ){
        self.deleteEvent(event)
        self.addEvent()
    }
    
    func fetchContacts() {
        let fetchContacts = NSFetchRequest<Contact>(entityName: "Contact")
        fetchContacts.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        
        let fetchEvents = NSFetchRequest<Event>(entityName: "Event")
        fetchEvents.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

        do {
            contacts = try PersistenceController.shared.container.viewContext.fetch(fetchContacts)
            events = try PersistenceController.shared.container.viewContext.fetch(fetchEvents)
            sortAllEvents()
            
            self.addEventTitel = ""
            self.addEventIcon = "bandage.fill"
            self.addEventStarDate = Date()
            self.addEventEndDate = Date()
            self.addEventContact = nil
            self.error = ""
            //fetchContacts()
            self.isAddEventSheet = false
        }catch {
          print("DEBUG: Some error occured while fetching Times")
        }
    }
    
    func sortAllEvents() {
        contacts = contacts
    }
    
    func deleteRecurringEvents(_ recurringEvents: RecurringEvents) {
        FK_EventProvider.shared.removeRecurringEvent(store: EKEventStore(), event: recurringEvents)
        
        withAnimation {
            viewContext.delete(recurringEvents)
            PushNotificationManager().removeNotification(identifier: recurringEvents.identifier ?? "Identifier")
            do {
                try viewContext.save()
                sortAllEvents()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteRecurringAllEvents(_ recurringEvents: RecurringEvents) {
        FK_EventProvider.shared.removeRecurringEvent(store: EKEventStore(), event: recurringEvents)

        withAnimation {
            viewContext.delete(recurringEvents)
            PushNotificationManager().removeNotification(identifier: recurringEvents.identifier ?? "Identifier")
            do {
                try viewContext.save()
                sortAllEvents()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteContact(_ contact: Contact) {
        withAnimation {
            // Search Relations in this Contact and delete all Notifications
            for event in contact.events?.allObjects as? [Event] ?? [] {
                PushNotificationManager().removeNotification(identifier: event.eventID ?? "Identifier")
                self.deleteEvent(event)
            }
            
            // Search Relations in this Contact and delete all Notifications
            for recurringEvent in contact.recurringEvents?.allObjects as? [RecurringEvents] ?? [] {
                PushNotificationManager().removeNotification(identifier: recurringEvent.identifier ?? "Identifier")
                self.deleteRecurringEvents(recurringEvent)
            }
            
            viewContext.delete(contact)
            
            do {
                try viewContext.save()
                fetchContacts()
                sortAllEvents()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }

        }
    }
    
    func deleteContactPerson(_ contactPerson: ContactPerson) {
        withAnimation {
            viewContext.delete(contactPerson)
            do {
                try viewContext.save()
                sortAllEvents()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }

        }
    }
    
    func deleteEvent(_ event: Event) {
        FK_EventProvider.shared.removeEvent(store: EKEventStore(), event: event)
        
        withAnimation {
            viewContext.delete(event)
            
            if event.eventID != nil {
                print("Notofication with \(String(describing: event.eventID)) deleted")
                PushNotificationManager().removeNotification(identifier: event.eventID!)
            }
            
            do {//events.filter { $0.id == event.id }.forEach(PersistenceController.shared.container.viewContext.delete)
                try viewContext.save()
                sortAllEvents()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteTask(_ task: EventTasks) {
        withAnimation{
            viewContext.delete(task)
              do {
                  try viewContext.save()
                  sortAllEvents()
              } catch {
                  let nsError = error as NSError
                  fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
              }
        }
    }

    func convertDateToNotoficationString(_ d: Date) -> (date: String, time: String) {
        let formattedDate = d.dateFormatte(date: "dd. MMM yyyy", time: "HH:mm")
        
        return (date: formattedDate.date, time: formattedDate.time)
    }
    
    func getImage(_ img: String) -> String {
        return self.contactTypes.first(where: { $0.type == img })?.image ?? "Illustration"
    }
    
    func getIcon(_ input: String) -> String {
        if input == "other" {
            return self.contactTypes.first(where: { $0.type == "Others" })?.icon ?? "person.crop.circle.badge.xmark"
        } else {
            return self.contactTypes.first(where: { $0.type == input })?.icon ?? "person.crop.circle.badge.xmark"
        }
    }
}


// Convenience methods for dates.
extension Date {
    var sevenDaysOut: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .day, value: 7, to: self) ?? self
    }
    
    var thirtyDaysOut: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .day, value: 30, to: self) ?? self
    }
}



/* Add Notification
 if let unwrapped = addEventContact?.name! {
     guard !sendEventNotofication else {
         let date = Calendar.current.date(byAdding: .day, value: -1, to: addEventDate)
         let bodyText = "Termin Erinnerung: \(convertDateToNotoficationString(addEventDate)), bei \(String(describing: unwrapped))"
         
         PushNotificationManager().PushNotificationByAddEvent(
             identifier: newEvent.eventID!,
             title: AppConfig().AppName,
             body: bodyText,
             triggerDate: date!,
             repeater: false)
         
         return
     }
 }
 */
