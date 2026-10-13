import 'package:flutter/widgets.dart';

import 'app_language.dart';

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.english;

  static AppLocalizations of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LocalizationScope>()!.value;

  String get welcome =>
      isEnglish ? 'Welcome to Perfomia' : 'Bienvenue sur Perfomia';
  String get loginSubtitle => isEnglish
      ? 'Sign in to access your workspace.'
      : 'Connectez-vous pour retrouver votre espace de travail.';
  String get email => isEnglish ? 'Email address' : 'Adresse e-mail';
  String get password => isEnglish ? 'Password' : 'Mot de passe';
  String get showPassword =>
      isEnglish ? 'Show password' : 'Afficher le mot de passe';
  String get hidePassword =>
      isEnglish ? 'Hide password' : 'Masquer le mot de passe';
  String get signIn => isEnglish ? 'Sign in' : 'Se connecter';
  String get validEmail => isEnglish
      ? 'Enter a valid email address.'
      : 'Saisissez une adresse e-mail valide.';
  String get shortPassword => isEnglish
      ? 'The password is too short.'
      : 'Le mot de passe est trop court.';
  String get retryError => isEnglish
      ? 'An error occurred. Please try again.'
      : 'Une erreur est survenue. Veuillez reessayer.';

  String get skip => isEnglish ? 'Skip' : 'Passer';
  String get next => isEnglish ? 'Continue' : 'Continuer';
  String get start => isEnglish ? 'Get started' : 'Commencer';
  String get onboardingWorkspace =>
      isEnglish ? 'Your workspace' : 'Votre espace de travail';
  String get onboardingWorkspaceDescription => isEnglish
      ? 'Find your indicators, priorities and important company information.'
      : 'Retrouvez vos indicateurs, vos priorites et les informations importantes de votre entreprise.';
  String get onboardingProjects =>
      isEnglish ? 'Projects and tasks' : 'Projets et taches';
  String get onboardingProjectsDescription => isEnglish
      ? 'Track your projects and tasks with a clear view of your responsibilities.'
      : 'Suivez vos projets et vos taches avec une vision claire de vos responsabilites.';
  String get onboardingNotifications =>
      isEnglish ? 'Stay informed' : 'Restez informe';
  String get onboardingNotificationsDescription => isEnglish
      ? 'Receive useful notifications at the right time and stay in control of your activity.'
      : 'Recevez les notifications utiles au bon moment et gardez le controle de votre activite.';

  String get languageTitle =>
      isEnglish ? 'Choose your language' : 'Choisissez votre langue';
  String get languageSubtitle => isEnglish
      ? 'You can change it later in your profile settings.'
      : 'Vous pourrez la modifier plus tard dans les preferences de votre profil.';
  String get french => 'Francais';
  String get english => 'English';
  String get appDescription => isEnglish
      ? 'Simple management for your daily work.'
      : 'La gestion simple de votre activite.';

  String get notifications => isEnglish ? 'Notifications' : 'Notifications';
  String get profile => isEnglish ? 'Profile' : 'Profil';
  String get home => isEnglish ? 'Home' : 'Accueil';
  String get projects => isEnglish ? 'Projects' : 'Projets';
  String get tasks => isEnglish ? 'Tasks' : 'Taches';
  String get courriers => isEnglish ? 'Mail' : 'Courriers';
  String get more => isEnglish ? 'More' : 'Plus';
  String get companyView => isEnglish ? 'Company view' : 'Vue entreprise';
  String get teamView => isEnglish ? 'Team view' : 'Vue equipe';
  String get personalView => isEnglish ? 'Personal view' : 'Vue personnelle';
  String get hello => isEnglish ? 'Hello' : 'Bonjour';
  String get activityOverview => isEnglish
      ? 'Here is an overview of your activity.'
      : 'Voici un apercu de votre activite.';
  String get dashboardLoadError => isEnglish
      ? 'Unable to load the dashboard.'
      : 'Impossible de charger le dashboard.';
  String get totalTasks => isEnglish ? 'Total tasks' : 'Total des taches';
  String get pendingTasks => isEnglish ? 'Pending tasks' : 'Taches en attente';
  String get completedTasks =>
      isEnglish ? 'Completed tasks' : 'Taches terminees';
  String get overdue => isEnglish ? 'Overdue' : 'En retard';
  String get projectsAtRisk =>
      isEnglish ? 'Projects at risk' : 'Projets a risque';
  String get pendingCourriers =>
      isEnglish ? 'Pending mail' : 'Courriers en attente';
  String get productivity => isEnglish ? 'Productivity' : 'Productivite';
  String get productivityDescription => isEnglish
      ? 'Score based on your tasks, projects and mail.'
      : 'Score base sur vos taches, projets et courriers.';
  String get recentTasks => isEnglish ? 'Recent tasks' : 'Taches recentes';
  String get recentTasksDescription => isEnglish
      ? 'The latest tasks in your scope.'
      : 'Les dernieres taches de votre perimetre.';
  String get noRecentTasks =>
      isEnglish ? 'No recent tasks.' : 'Aucune tache recente.';
  String get viewAllTasks =>
      isEnglish ? 'View all tasks' : 'Voir toutes les taches';
  String dueDate(String date) => isEnglish ? 'Due $date' : 'Echeance $date';
  String get completed => isEnglish ? 'Completed' : 'Terminee';
  String get inProgress => isEnglish ? 'In progress' : 'En cours';
  String get todo => isEnglish ? 'To do' : 'A faire';
  String get moreDescription => isEnglish
      ? 'Find secondary access points for your workspace here.'
      : 'Retrouvez ici les acces secondaires de votre espace de travail.';
  String get quickAccess => isEnglish ? 'Quick access' : 'Acces rapides';
  String get account => isEnglish ? 'Account' : 'Compte';
  String get reports => isEnglish ? 'Reports' : 'Rapports';
  String get reportsDescription => isEnglish
      ? 'View your activity indicators'
      : 'Consulter les indicateurs de votre activite';
  String get evaluations => isEnglish ? 'Evaluations' : 'Evaluations';
  String get evaluationsDescription => isEnglish
      ? 'Follow your available evaluations'
      : 'Suivre les evaluations accessibles';
  String get settings => isEnglish ? 'Settings' : 'Parametres';
  String get settingsDescription => isEnglish
      ? 'Manage your workspace settings'
      : 'Reglages de votre espace de travail';
  String get notificationsDescription => isEnglish
      ? 'Check your alerts and reminders'
      : 'Consulter vos alertes et rappels';
  String get signOut => isEnglish ? 'Sign out' : 'Se deconnecter';
  String get signOutDescription => isEnglish
      ? 'Close your session on this device'
      : 'Fermer votre session sur cet appareil';
  String get projectsDescription => isEnglish
      ? 'Follow the projects you can access.'
      : 'Suivez les projets auxquels vous avez acces.';
  String get searchProject =>
      isEnglish ? 'Search for a project...' : 'Rechercher un projet...';
  String get filterByStatus =>
      isEnglish ? 'Filter by status' : 'Filtrer par statut';
  String get loadingError =>
      isEnglish ? 'Unable to load' : 'Chargement impossible';
  String get retry => isEnglish ? 'Retry' : 'Reessayer';
  String get noProject => isEnglish ? 'No project' : 'Aucun projet';
  String get projectsWillAppear => isEnglish
      ? 'Available projects will appear here.'
      : 'Les projets disponibles apparaitront ici.';
  String get add => isEnglish ? 'Add' : 'Ajouter';
  String get planned => isEnglish ? 'Planned' : 'Planifies';
  String get active => isEnglish ? 'Active' : 'Actifs';
  String get onHold => isEnglish ? 'On hold' : 'En attente';
  String get finished => isEnglish ? 'Completed' : 'Termines';
  String get archived => isEnglish ? 'Archived' : 'Archives';
  String get cancelled => isEnglish ? 'Cancelled' : 'Annules';
  String get tasksDescription => isEnglish
      ? 'Follow the tasks that concern you and their progress.'
      : 'Suivez les taches qui vous concernent et leur progression.';
  String get searchTask =>
      isEnglish ? 'Search for a task...' : 'Rechercher une tache...';
  String get filterTasks => isEnglish ? 'Filter tasks' : 'Filtrer les taches';
  String get list => isEnglish ? 'List' : 'Liste';
  String get calendar => isEnglish ? 'Calendar' : 'Calendrier';
  String get noTask => isEnglish ? 'No task' : 'Aucune tache';
  String get tasksWillAppear => isEnglish
      ? 'Tasks matching your filters will appear here.'
      : 'Les taches correspondant a vos filtres apparaitront ici.';
  String get allStatuses => isEnglish ? 'All statuses' : 'Tous les statuts';
  String get toDo => isEnglish ? 'To do' : 'A faire';
  String get underReview => isEnglish ? 'In review' : 'En revue';
  String get allPriorities =>
      isEnglish ? 'All priorities' : 'Toutes les priorites';
  String get low => isEnglish ? 'Low' : 'Basse';
  String get medium => isEnglish ? 'Medium' : 'Moyenne';
  String get high => isEnglish ? 'High' : 'Haute';
  String get urgent => isEnglish ? 'Urgent' : 'Urgente';
  String get scope => isEnglish ? 'Scope' : 'Perimetre';
  String get allVisibleTasks =>
      isEnglish ? 'All visible tasks' : 'Toutes les taches visibles';
  String get myTasks => isEnglish ? 'My tasks' : 'Mes taches';
  String get taskCreated => isEnglish ? 'Task created.' : 'Tache creee.';
  String get noTasksForDate =>
      isEnglish ? 'No tasks on this date' : 'Aucune tache ce jour';
  String get tasksForDateWillAppear => isEnglish
      ? 'Tasks scheduled for this date will appear here.'
      : 'Les taches planifiees pour cette date apparaitront ici.';
  String get previousMonth => isEnglish ? 'Previous month' : 'Mois precedent';
  String get nextMonth => isEnglish ? 'Next month' : 'Mois suivant';
  String get apply => isEnglish ? 'Apply' : 'Appliquer';
  String get cancel => isEnglish ? 'Cancel' : 'Annuler';
  String get priority => isEnglish ? 'Priority' : 'Priorite';
  String get team => isEnglish ? 'Team' : 'Equipe';
  String get noMembers =>
      isEnglish ? 'No members added.' : 'Aucun membre renseigne.';
  String get projectModules =>
      isEnglish ? 'Project modules' : 'Modules du projet';
  String get milestones => isEnglish ? 'Milestones' : 'Jalons';
  String get milestonesDescription =>
      isEnglish ? 'Important steps' : 'Etapes importantes';
  String get deliverables => isEnglish ? 'Deliverables' : 'Livrables';
  String get deliverablesDescription => isEnglish
      ? 'Items to submit and approve'
      : 'Elements a remettre et a valider';
  String get attentionPoints =>
      isEnglish ? 'Attention points' : 'Points d attention';
  String get attentionPointsDescription => isEnglish
      ? 'Risks, blockers and decisions'
      : 'Risques, blocages et decisions';
  String get timeAndBudget => isEnglish ? 'Time and budget' : 'Temps et budget';
  String get loggedProjectTime => isEnglish
      ? 'Time logged on the project'
      : 'Temps journalise sur le projet';
  String get projectActivity =>
      isEnglish ? 'Project activity' : 'Activite du projet';
  String get actionHistory =>
      isEnglish ? 'Action history' : 'Historique des actions';
  String get progress => isEnglish ? 'Progress' : 'Progression';
  String get noDueDate => isEnglish ? 'No due date' : 'Sans echeance';
  String get ownerUndefined =>
      isEnglish ? 'Owner not defined' : 'Responsable non defini';
  String get taskDetails => isEnglish ? 'Task details' : 'Details de la tache';
  String get subtasks => isEnglish ? 'Subtasks' : 'Sous-taches';
  String get files => isEnglish ? 'Files' : 'Fichiers';
  String get comments => isEnglish ? 'Comments' : 'Commentaires';
  String get closureReport =>
      isEnglish ? 'Closure report' : 'Rapport de cloture';
  String get noSubtasks =>
      isEnglish ? 'No subtasks yet.' : 'Aucune sous-tache pour le moment.';
  String get addComment =>
      isEnglish ? 'Add a comment' : 'Ajouter un commentaire';
  String get addFile => isEnglish ? 'Add a file' : 'Ajouter un fichier';
  String get addReport => isEnglish ? 'Add a report' : 'Ajouter un rapport';
  String get editTask => isEnglish ? 'Edit task' : 'Modifier la tache';
  String get editPriority =>
      isEnglish ? 'Edit priority' : 'Modifier la priorite';
  String get reassignTask =>
      isEnglish ? 'Reassign task' : 'Reassigner la tache';
  String get startTask => isEnglish ? 'Start task' : 'Commencer la tache';
  String get extendDueDate =>
      isEnglish ? 'Extend due date' : 'Prolonger l echeance';
  String get acceptAssignment =>
      isEnglish ? 'Accept assignment' : 'Accepter l affectation';
  String get declineAssignment =>
      isEnglish ? 'Decline assignment' : 'Refuser l affectation';
  String get validateReport =>
      isEnglish ? 'Approve report' : 'Valider le rapport';
  String get rejectReport => isEnglish ? 'Reject report' : 'Rejeter le rapport';
  String get deleteTask => isEnglish ? 'Delete task' : 'Supprimer la tache';
  String get newProject => isEnglish ? 'New project' : 'Nouveau projet';
  String get editProject => isEnglish ? 'Edit project' : 'Modifier le projet';
  String get projectName => isEnglish ? 'Project name' : 'Nom du projet';
  String get description => isEnglish ? 'Description' : 'Description';
  String get projectPeriod =>
      isEnglish ? 'Project period' : 'Periode du projet';
  String get selectDates => isEnglish
      ? 'Select a start and end date'
      : 'Selectionner une date de debut et de fin';
  String get confidentialProject =>
      isEnglish ? 'Confidential project' : 'Projet confidentiel';
  String get initialTeam => isEnglish ? 'Initial team' : 'Equipe initiale';
  String get member => isEnglish ? 'Member' : 'Membre';
  String get role => isEnglish ? 'Role' : 'Role';
  String get noMemberAdded =>
      isEnglish ? 'No member added.' : 'Aucun membre ajoute.';
  String get createProject => isEnglish ? 'Create project' : 'Creer le projet';
  String get save => isEnglish ? 'Save' : 'Enregistrer';
  String get newTask => isEnglish ? 'New task' : 'Ajouter une tache';
  String get independentTaskDescription => isEnglish
      ? 'Create a task independent of a project.'
      : 'Creez une tache independante d un projet.';
  String get title => isEnglish ? 'Title' : 'Titre';
  String get linkedProject => isEnglish ? 'Linked project' : 'Projet lie';
  String get generalTask => isEnglish ? 'General task' : 'Tache generale';
  String get forMe => isEnglish ? 'For me' : 'Pour moi';
  String get collaborator => isEnglish ? 'Collaborator' : 'Collaborateur';
  String get assignTo => isEnglish ? 'Assign to' : 'Assigner a';
  String get definePeriod => isEnglish ? 'Set period' : 'Definir la periode';
  String get createTask => isEnglish ? 'Create task' : 'Creer la tache';
  String get requiredTitle =>
      isEnglish ? 'Title is required.' : 'Le titre est obligatoire.';
  String get datesRequired => isEnglish
      ? 'Start date and due date are required.'
      : 'Le debut et l echeance sont obligatoires.';
  String get dueAfterStart => isEnglish
      ? 'The due date must be after the start date.'
      : 'L echeance doit etre apres le debut.';
  String get notificationsTitle =>
      isEnglish ? 'Notifications' : 'Notifications';
  String get markAllRead => isEnglish ? 'Mark all as read' : 'Tout lire';
  String get clear => isEnglish ? 'Clear' : 'Effacer';
  String get filterNotifications =>
      isEnglish ? 'Filter notifications' : 'Filtrer les notifications';
  String get notificationState => isEnglish ? 'State' : 'Etat';
  String get allNotifications =>
      isEnglish ? 'All notifications' : 'Toutes les notifications';
  String get unread => isEnglish ? 'Unread' : 'Non lues';
  String get read => isEnglish ? 'Read' : 'Lues';
  String get searchNotification =>
      isEnglish ? 'Search a notification' : 'Rechercher une notification';
  String get actions => isEnglish ? 'Actions' : 'Actions';
  String get markAsRead => isEnglish ? 'Mark as read' : 'Marquer comme lue';
  String get delete => isEnglish ? 'Delete' : 'Supprimer';
  String get noNotifications =>
      isEnglish ? 'No notification found' : 'Aucune notification trouvee';
  String get notificationsWillAppear => isEnglish
      ? 'New alerts will appear here when available.'
      : 'Les nouvelles alertes apparaitront ici des qu elles seront disponibles.';
  String get unknownDate => isEnglish ? 'Unknown date' : 'Date inconnue';
  String get unableToLoadNotifications => isEnglish
      ? 'Unable to load notifications.'
      : 'Impossible de charger les notifications.';
  String get courrierTitle => isEnglish ? 'Mail' : 'Courriers';
  String get courriersDescription => isEnglish
      ? 'View the mail that concerns you and its processing status.'
      : 'Consultez les courriers qui vous concernent et leur etat de traitement.';
  String get filterCourriers =>
      isEnglish ? 'Filter mail' : 'Filtrer les courriers';
  String get courrierType => isEnglish ? 'Mail type' : 'Type de courrier';
  String get incoming => isEnglish ? 'Incoming' : 'Entrants';
  String get outgoing => isEnglish ? 'Outgoing' : 'Sortants';
  String get allCourrierTypes => isEnglish ? 'All types' : 'Tous les types';
  String get courrierStatus => isEnglish ? 'Status' : 'Statut';
  String get perimeter => isEnglish ? 'Scope' : 'Perimetre';
  String get allVisibleCourriers =>
      isEnglish ? 'All visible mail' : 'Tous les courriers visibles';
  String get myCourriers => isEnglish ? 'My mail' : 'Mes courriers';
  String get searchCourrier => isEnglish
      ? 'Search a reference or subject...'
      : 'Rechercher une reference ou un objet...';
  String get addCourrier => isEnglish ? 'Add' : 'Ajouter';
  String get activeCourriers =>
      isEnglish ? 'View active mail' : 'Voir les courriers actifs';
  String get archivedCourriers =>
      isEnglish ? 'View archived mail' : 'Voir les courriers archives';
  String get noCourrier =>
      isEnglish ? 'No mail found' : 'Aucun courrier trouve';
  String get unableToLoadCourriers => isEnglish
      ? 'Unable to load mail.'
      : 'Impossible de charger les courriers.';
  String get courrierDetails =>
      isEnglish ? 'Mail details' : 'Detail du courrier';
  String get transmit => isEnglish ? 'Transmit' : 'Transmettre';
  String get remind => isEnglish ? 'Remind' : 'Relancer';
  String get closeCourrier => isEnglish ? 'Close' : 'Cloturer';
  String get archiveCourrier => isEnglish ? 'Archive' : 'Archiver';
  String get confirmReception =>
      isEnglish ? 'Confirm receipt' : 'Confirmer la reception';
  String get process => isEnglish ? 'Process' : 'Traiter';
  String get courrierPath => isEnglish ? 'Mail path' : 'Parcours du courrier';
  String get confidential => isEnglish ? 'Confidential' : 'Confidentiel';
  String get fromMe =>
      isEnglish ? 'This mail is from me' : 'Le courrier vient de moi';
  String get saveCourrier =>
      isEnglish ? 'Save mail' : 'Enregistrer le courrier';
  String get createTaskForRecipient =>
      isEnglish ? 'Create a task' : 'Creer une tache';
  String get taskForRecipientDescription => isEnglish
      ? 'Assign a task to the recipient'
      : 'Assigner une tache au destinataire';
  String get retain => isEnglish ? 'Retain' : 'Conserver';
  String get forInformation =>
      isEnglish ? 'For information' : 'Pour information';
  String get evaluationTitle => isEnglish ? 'Evaluations' : 'Evaluations';
  String get searchCollaborator => isEnglish
      ? 'Search for a collaborator...'
      : 'Rechercher un collaborateur...';
  String get startMyEvaluation =>
      isEnglish ? 'Start my evaluation' : 'Commencer mon evaluation';
  String get evaluationDetails =>
      isEnglish ? 'Evaluation details' : 'Detail evaluation';
  String get answer => isEnglish ? 'Your answer' : 'Votre reponse';
  String get writeCompleteAnswer => isEnglish
      ? 'Write a complete answer...'
      : 'Ecrivez une reponse complete...';
  String get previous => isEnglish ? 'Previous' : 'Precedent';
  String get review => isEnglish ? 'Review' : 'Reviser';
  String get submit => isEnglish ? 'Submit' : 'Soumettre';
  String get reportsTitle => isEnglish ? 'Reports' : 'Rapports';
  String get myPerformance => isEnglish ? 'My performance' : 'Ma performance';
  String get reportActivityDescription => isEnglish
      ? 'Analyze your activity in the same scope as Performa.'
      : 'Analysez votre activite sur le meme perimetre que Performa.';
  String get reportPeriodCustom =>
      isEnglish ? 'Custom period' : 'Periode personnalisee';
  String get reportLast30Days =>
      isEnglish ? 'Last 30 days' : '30 derniers jours';
  String get topEmployees => isEnglish ? 'Top employees' : 'Meilleurs employes';
  String get total => isEnglish ? 'Total' : 'Total';
  String get pending => isEnglish ? 'Pending' : 'En attente';
  String get atRisk => isEnglish ? 'At risk' : 'A risque';
  String get internal => isEnglish ? 'Internal' : 'Internes';
  String get inReview => isEnglish ? 'In review' : 'En revue';
  String get productivityOverall =>
      isEnglish ? 'Overall productivity' : 'Productivite globale';
  String get reportScoreDescription => isEnglish
      ? 'Score based on your tasks, projects and mail.'
      : 'Score base sur vos taches, projets et courriers.';
  String get totalProjects => isEnglish ? 'Total projects' : 'Projets totaux';
  String get activeProjects => isEnglish ? 'Active projects' : 'Projets actifs';
  String get totalCourriers => isEnglish ? 'Total mail' : 'Courriers totaux';
  String get overdueTasks => isEnglish ? 'Overdue tasks' : 'Taches en retard';
  String get productivityEvolution =>
      isEnglish ? 'Productivity trend' : 'Evolution de la productivite';
  String get taskEvolution => isEnglish ? 'Task trend' : 'Evolution des taches';
  String get projectEvolution =>
      isEnglish ? 'Project trend' : 'Evolution des projets';
  String get courrierEvolution =>
      isEnglish ? 'Mail trend' : 'Evolution des courriers';
  String get statusDistribution =>
      isEnglish ? 'Status distribution' : 'Repartition par statut';
  String get byStatus => isEnglish ? 'By status' : 'Par statut';
  String get byType => isEnglish ? 'By type' : 'Par type';
  String get noReportData =>
      isEnglish ? 'No report data available.' : 'Aucune donnee disponible.';
  String get reportLoadError => isEnglish
      ? 'Unable to load reports.'
      : 'Impossible de charger les rapports.';
  String get exportPdfError =>
      isEnglish ? 'PDF export failed: ' : 'Export PDF impossible : ';
  String get exportExcelError =>
      isEnglish ? 'Excel export failed: ' : 'Export Excel impossible : ';
  String get indicator => isEnglish ? 'Indicator' : 'Indicateur';
  String get value => isEnglish ? 'Value' : 'Valeur';
  String get export => isEnglish ? 'Export' : 'Exporter';
  String get exportPdf => isEnglish ? 'Export as PDF' : 'Exporter en PDF';
  String get exportExcel => isEnglish ? 'Export as Excel' : 'Exporter en Excel';
  String get noData =>
      isEnglish ? 'No data available.' : 'Aucune donnee disponible.';
  String get profileTitle => isEnglish ? 'My profile' : 'Mon profil';
  String get firstName => isEnglish ? 'First name' : 'Prenom';
  String get lastName => isEnglish ? 'Last name' : 'Nom';
  String get currentPassword =>
      isEnglish ? 'Current password' : 'Mot de passe actuel';
  String get confirmPassword =>
      isEnglish ? 'Confirm password' : 'Confirmer le mot de passe';
  String get timezone => isEnglish ? 'Time zone' : 'Fuseau horaire';
  String get preferences => isEnglish ? 'Preferences' : 'Preferences';
  String get jobProfile => isEnglish ? 'Job profile' : 'Fiche de poste';
  String get edit => isEnglish ? 'Edit' : 'Modifier';
  String get addJobProfile => isEnglish ? 'Add' : 'Ajouter';
  String get noJobProfile =>
      isEnglish ? 'No job profile' : 'Aucune fiche de poste';
  String get personalInformation =>
      isEnglish ? 'Personal information' : 'Informations personnelles';
  String get security => isEnglish ? 'Security' : 'Securite';
  String get changePassword =>
      isEnglish ? 'Change password' : 'Modifier le mot de passe';
  String get changePasswordDescription => isEnglish
      ? 'Change your account password'
      : 'Modifier le mot de passe du compte';
  String get preferencesAndNotifications => isEnglish
      ? 'Preferences and notifications'
      : 'Preferences et notifications';
  String get timezoneLabel => isEnglish ? 'Time zone' : 'Fuseau horaire';
  String get defaultHome => isEnglish ? 'Default home' : 'Accueil par defaut';
  String get dashboard => isEnglish ? 'Dashboard' : 'Tableau de bord';
  String get inAppNotifications =>
      isEnglish ? 'In-app notifications' : 'Notifications dans l application';
  String get emailNotifications =>
      isEnglish ? 'Email notifications' : 'Notifications e-mail';
  String get taskNotifications =>
      isEnglish ? 'Task notifications' : 'Notifications taches';
  String get evaluationNotifications =>
      isEnglish ? 'Evaluation notifications' : 'Notifications evaluations';
  String get courrierNotifications =>
      isEnglish ? 'Mail notifications' : 'Notifications courriers';
  String get settingsTitle => isEnglish ? 'Settings' : 'Parametres';
  String get activityLog => isEnglish ? 'Activity log' : 'Journal d activite';
  String get usersTitle => isEnglish ? 'Users' : 'Utilisateurs';
  String get departmentsTitle => isEnglish ? 'Departments' : 'Departements';
  String get servicesTitle => isEnglish ? 'Services' : 'Services';
  String get supervisorsTitle => isEnglish ? 'Supervisors' : 'Superviseurs';
  String get productivityTitle => isEnglish ? 'Productivity' : 'Productivite';
  String get questionsTitle =>
      isEnglish ? 'Evaluation questions' : 'Questions d evaluation';
  String get criteriaTitle =>
      isEnglish ? 'Evaluation criteria' : 'Criteres d evaluation';
  String get addUser => isEnglish ? 'Add user' : 'Ajouter un utilisateur';
  String get addDepartment =>
      isEnglish ? 'Add department' : 'Ajouter un departement';
  String get addService => isEnglish ? 'Add service' : 'Ajouter un service';
  String get departmentAdded =>
      isEnglish ? 'Department added.' : 'Departement ajoute.';
  String get serviceAdded => isEnglish ? 'Service added.' : 'Service ajoute.';
  String get noDataAvailable => isEnglish
      ? 'No item is available at the moment.'
      : 'Aucun element n est disponible pour le moment.';
  String get requiredField =>
      isEnglish ? 'Required field.' : 'Champ obligatoire.';
  String get selectDepartment =>
      isEnglish ? 'Select a department.' : 'Selectionnez un departement.';
  String get name => isEnglish ? 'Name' : 'Nom';
  String get descriptionLabel => isEnglish ? 'Description' : 'Description';
  String get refresh => isEnglish ? 'Refresh' : 'Actualiser';
  String get search => isEnglish ? 'Search' : 'Rechercher';
  String get previousPage => isEnglish ? 'Previous' : 'Precedent';
  String get nextPage => isEnglish ? 'Next' : 'Suivant';
  String get deleteConfirmation => isEnglish ? 'Delete?' : 'Supprimer ?';
  String get confirmAction => isEnglish ? 'Confirm' : 'Confirmer';
  String get noResults =>
      isEnglish ? 'No results found.' : 'Aucun resultat trouve.';
  String get reload => isEnglish ? 'Retry' : 'Reessayer';
  String get weightsInvalid => isEnglish
      ? 'Weights must be 40 / 40 / 10 / 10.'
      : 'Les ponderations doivent etre 40 / 40 / 10 / 10.';
  String get settingsUpdated => isEnglish
      ? 'Company settings updated.'
      : 'Parametres de l entreprise mis a jour.';
  String get companyRequired => isEnglish
      ? 'Company name and email are required.'
      : 'Le nom et l email de l entreprise sont obligatoires.';
  String get companyUpdated => isEnglish
      ? 'Company information updated.'
      : 'Informations de l entreprise mises a jour.';
  String get saveInformation =>
      isEnglish ? 'Save information' : 'Enregistrer les informations';
  String get dateFormat => isEnglish ? 'Date format' : 'Format date';
  String get timeFormat => isEnglish ? 'Time format' : 'Format heure';
  String get incomingAdded =>
      isEnglish ? 'Incoming mail added.' : 'Courrier entrant ajoute.';
  String get outgoingAdded =>
      isEnglish ? 'Outgoing mail added.' : 'Courrier sortant ajoute.';
  String get mailTransmitted =>
      isEnglish ? 'Mail transmitted.' : 'Courrier transmis.';
  String get mailAndTaskCreated => isEnglish
      ? 'Mail transmitted and task created.'
      : 'Courrier transmis et tache creee.';
  String get noCourrierMatch => isEnglish
      ? 'No mail matches your filters.'
      : 'Aucun courrier ne correspond a vos filtres.';
  String get addIncoming =>
      isEnglish ? 'Add incoming mail' : 'Ajouter un courrier entrant';
  String get addOutgoing =>
      isEnglish ? 'Add outgoing mail' : 'Ajouter un courrier sortant';
  String get saveMail => isEnglish ? 'Save mail' : 'Enregistrer le courrier';
  String get campaign => isEnglish ? 'Campaign' : 'Campagne';
  String get noAnswer => isEnglish ? 'No answer' : 'Aucune reponse';
  String get editAnswers =>
      isEnglish ? 'Edit my answers' : 'Modifier mes reponses';
  String get submitting => isEnglish ? 'Submitting...' : 'Envoi en cours...';
  String get submitAnswers =>
      isEnglish ? 'Submit answers' : 'Soumettre les reponses';
  String get configuration => isEnglish ? 'Configuration' : 'Configuration';
  String get personalSettingsNotice => isEnglish
      ? 'Personal preferences remain in your profile. The settings below concern your workspace.'
      : 'Les preferences personnelles restent dans votre profil. Les reglages ci-dessous concernent l espace de travail.';
  String get organization => isEnglish ? 'Organization' : 'Organisation';
  String get evaluationsSection => isEnglish ? 'Evaluations' : 'Evaluations';
  String get companySettings => isEnglish ? 'Company' : 'Entreprise';
  String get companySettingsDescription => isEnglish
      ? 'Features, notifications and global rules.'
      : 'Fonctionnalites, notifications et regles globales.';
  String get companyInformation =>
      isEnglish ? 'Company information' : 'Informations de l entreprise';
  String get companyInformationDescription => isEnglish
      ? 'Update the information visible on the platform.'
      : 'Mettez a jour les informations visibles dans la plateforme.';
  String get companyName => isEnglish ? 'Company name' : 'Nom de l entreprise';
  String get phone => isEnglish ? 'Phone' : 'Telephone';
  String get address => isEnglish ? 'Address' : 'Adresse';
  String get country => isEnglish ? 'Country' : 'Pays';
  String get companyStatus => isEnglish ? 'Status' : 'Statut';
  String get modules => isEnglish ? 'Modules' : 'Modules';
  String get modulesDescription => isEnglish
      ? 'Enable the features available in the workspace.'
      : 'Activez les fonctionnalites disponibles dans l espace de travail.';
  String get globalNotifications =>
      isEnglish ? 'Global notifications' : 'Notifications globales';
  String get whatsappNotifications =>
      isEnglish ? 'WhatsApp notifications' : 'Notifications WhatsApp';
  String get taskManagement =>
      isEnglish ? 'Task management' : 'Gestion des taches';
  String get mailManagement =>
      isEnglish ? 'Mail management' : 'Gestion des courriers';
  String get aiEvaluation => isEnglish ? 'AI evaluation' : 'Evaluation par IA';
  String get general => isEnglish ? 'General' : 'General';
  String get generalDescription => isEnglish
      ? 'Define the default language, time zone and formats.'
      : 'Definissez la langue, le fuseau horaire et les formats par defaut.';
  String get defaultLanguage =>
      isEnglish ? 'Default language' : 'Langue par defaut';
  String get frenchLanguage => isEnglish ? 'French' : 'Francais';
  String get englishLanguage => isEnglish ? 'English' : 'Anglais';
  String get hourFormat => isEnglish ? 'Time format' : 'Format heure';
  String get twentyFourHours => isEnglish ? '24 hours' : '24 heures';
  String get twelveHours => isEnglish ? '12 hours' : '12 heures';
  String get evaluationSettingsDescription => isEnglish
      ? 'Set the campaign opening and score weighting.'
      : 'Definissez l ouverture de la campagne et les ponderations du score.';
  String get evaluationStartDate =>
      isEnglish ? 'Evaluation start date' : 'Debut des evaluations';
  String get chooseDateTime =>
      isEnglish ? 'Choose a date and time' : 'Choisir une date et une heure';
  String get removeDate => isEnglish ? 'Remove date' : 'Retirer la date';
  String get openingDate => isEnglish ? 'Opening date' : 'Date d ouverture';
  String get openingTime => isEnglish ? 'Opening time' : 'Heure d ouverture';
  String get continueLabel => isEnglish ? 'Continue' : 'Continuer';
  String get validate => isEnglish ? 'Confirm' : 'Valider';
  String get saveSettings =>
      isEnglish ? 'Save settings' : 'Enregistrer les parametres';
  String get questionsCount =>
      isEnglish ? 'Number of questions' : 'Nombre de questions';
  String get taskWeight => isEnglish ? 'Tasks (%)' : 'Taches (%)';
  String get managerWeight => isEnglish ? 'Manager (%)' : 'Superieur (%)';
  String get adminWeight => isEnglish ? 'Admin (%)' : 'Admin (%)';
  String get courrierSettingsDescription => isEnglish
      ? 'Configure mail references and automatic archiving.'
      : 'Configurez la reference et l archivage automatique des courriers.';
  String get referencePrefix =>
      isEnglish ? 'Reference prefix' : 'Prefixe de reference';
  String get autoArchive =>
      isEnglish ? 'Automatic archiving' : 'Archivage automatique';
  String get archiveDelay => isEnglish
      ? 'Delay before archiving (days)'
      : 'Delai avant archivage (jours)';
  String get usersDescription => isEnglish
      ? 'Accounts, roles, positions and availability.'
      : 'Comptes, roles, postes et disponibilite.';
  String get departmentsDescription => isEnglish
      ? 'Department structure and assignments.'
      : 'Structure et rattachement des departements.';
  String get servicesDescription => isEnglish
      ? 'Services and internal work circulation.'
      : 'Services et circulation interne du travail.';
  String get supervisorsDescription => isEnglish
      ? 'Supervision and organizational assignments.'
      : 'Supervision et rattachements organisationnels.';
  String get productivityDescriptionSettings => isEnglish
      ? 'Rules and productivity tracking activation.'
      : 'Regles et activation du suivi de productivite.';
  String get activityLogDescription => isEnglish
      ? 'History of important company actions.'
      : 'Historique des actions importantes de l entreprise.';
  String get questionsDescription => isEnglish
      ? 'Questions used during evaluations.'
      : 'Questions utilisees pendant les evaluations.';
  String get criteriaDescription => isEnglish
      ? 'Rating grid for managers.'
      : 'Grille de notation des responsables.';
  String get userManagement =>
      isEnglish ? 'User management' : 'Gestion des utilisateurs';
  String get usersPageDescription => isEnglish
      ? 'Add and view accounts in your company.'
      : 'Ajoutez et consultez les comptes de votre entreprise.';
  String get noUsers => isEnglish ? 'No users' : 'Aucun utilisateur';
  String get addFirstUser => isEnglish
      ? 'Add the first user in your workspace.'
      : 'Ajoutez le premier utilisateur de votre espace.';
  String get invite => isEnglish ? 'Invite' : 'Inviter';
  String get userAdded => isEnglish ? 'User added.' : 'Utilisateur ajoute.';
  String get userUpdated =>
      isEnglish ? 'User updated.' : 'Utilisateur mis a jour.';
  String get inviteUser =>
      isEnglish ? 'Invite a user' : 'Inviter un utilisateur';
  String get optionalEmail =>
      isEnglish ? 'Email address (optional)' : 'Adresse e-mail (optionnelle)';
  String get targetRole => isEnglish ? 'Target role' : 'Role cible';
  String get employee => isEnglish ? 'Employee' : 'Employe';
  String get manager => isEnglish ? 'Manager' : 'Manager';
  String get superAdmin => isEnglish ? 'Super admin' : 'Super admin';
  String get generateLink => isEnglish ? 'Generate link' : 'Generer le lien';
  String get invitationGenerated =>
      isEnglish ? 'Invitation generated' : 'Invitation generee';
  String get copy => isEnglish ? 'Copy' : 'Copier';
  String get close => isEnglish ? 'Close' : 'Fermer';
  String get copied => isEnglish ? 'Token copied.' : 'Token copie.';
  String get invitationCreated =>
      isEnglish ? 'Invitation created.' : 'Invitation creee.';
  String get userDetails => isEnglish ? 'View details' : 'Voir le detail';
  String get resetPassword =>
      isEnglish ? 'Reset password' : 'Reinitialiser le mot de passe';
  String get newPassword => isEnglish ? 'New password' : 'Nouveau mot de passe';
  String get confirmation => isEnglish ? 'Confirmation' : 'Confirmation';
  String get passwordOptional => isEnglish
      ? 'New password (optional)'
      : 'Nouveau mot de passe (optionnel)';
  String get temporaryPassword =>
      isEnglish ? 'Temporary password' : 'Mot de passe temporaire';
  String get reset => isEnglish ? 'Reset' : 'Reinitialiser';
  String get resetPasswordHint => isEnglish
      ? 'Leave blank to generate a temporary password.'
      : 'Laissez vide pour generer un mot de passe temporaire.';
  String get deleteUserTitle =>
      isEnglish ? 'Delete user?' : 'Supprimer l utilisateur ?';
  String deleteUserMessage(String name) => isEnglish
      ? 'The account of $name will be deleted.'
      : 'Le compte de $name sera supprime.';
  String get viewDetails => isEnglish ? 'View details' : 'Voir le detail';
  String get notProvided => isEnglish ? 'Not provided' : 'Non renseigne';
  String get employmentStatus =>
      isEnglish ? 'Employment status' : 'Statut d emploi';
  String get availability => isEnglish ? 'Availability' : 'Disponibilite';
  String get available => isEnglish ? 'Available' : 'Disponible';
  String get onLeave => isEnglish ? 'On leave' : 'En conge';
  String get permission => isEnglish ? 'Permission' : 'Permission';
  String get inactive => isEnglish ? 'Inactive' : 'Inactif';
  String get terminated => isEnglish ? 'Terminated' : 'Fin de contrat';
  String get organizationSection => isEnglish ? 'Organization' : 'Organisation';
  String get accessSection => isEnglish ? 'Access' : 'Acces';
  String get availabilityStatusSection =>
      isEnglish ? 'Status and availability' : 'Statut et disponibilite';
  String get startUnavailable =>
      isEnglish ? 'Unavailability start' : 'Debut de l indisponibilite';
  String get endUnavailable =>
      isEnglish ? 'Unavailability end' : 'Fin de l indisponibilite';
  String get unavailableReason =>
      isEnglish ? 'Reason for unavailability' : 'Motif de l indisponibilite';
  String get saveChanges =>
      isEnglish ? 'Save changes' : 'Enregistrer les modifications';
  String get createAccount => isEnglish ? 'Create account' : 'Creer le compte';
  String get admin => isEnglish ? 'Admin' : 'Admin';
  String get jobTitle => isEnglish ? 'Position' : 'Poste';
  String get department => isEnglish ? 'Department' : 'Departement';
  String get service => isEnglish ? 'Service' : 'Service';
  String get supervisor => isEnglish ? 'Supervisor' : 'Responsable';
  String get noSupervisor => isEnglish ? 'No supervisor' : 'Aucun responsable';
  String get status => isEnglish ? 'Status' : 'Statut';
  String get mail => isEnglish ? 'Email' : 'E-mail';
  String get position => isEnglish ? 'Position' : 'Poste';
  String get reason => isEnglish ? 'Reason' : 'Motif';
  String get passwordReset =>
      isEnglish ? 'Password reset.' : 'Mot de passe reinitialise.';
  String get userDeleted =>
      isEnglish ? 'User deleted.' : 'Utilisateur supprime.';
  String get userSaved =>
      isEnglish ? 'User updated.' : 'Utilisateur mis a jour.';
  String get user => isEnglish ? 'User' : 'Utilisateur';
  String get supervisionScope => isEnglish ? 'Scope' : 'Perimetre';
  String get allScopes => isEnglish ? 'All scopes' : 'Tous les perimetres';
  String get companyScope => isEnglish ? 'Company' : 'Societe';
  String get serviceScope =>
      isEnglish ? 'Service / agency' : 'Service / agence';
  String get applyFilters => isEnglish ? 'Apply' : 'Appliquer';
  String get resetFilters => isEnglish ? 'Reset' : 'Reinitialiser';
  String get searchSupervisor =>
      isEnglish ? 'Search for a supervisor...' : 'Rechercher un superviseur...';
  String get supervisorRequired => isEnglish
      ? 'The supervisor and scope are required.'
      : 'Le superviseur et son perimetre sont obligatoires.';
  String get deleteSupervisorTitle =>
      isEnglish ? 'Delete this supervisor?' : 'Supprimer ce superviseur ?';
  String get deleteSupervisorMessage => isEnglish
      ? 'Their supervision rights will be removed.'
      : 'Ses droits de supervision seront retires.';
  String get userRequired => isEnglish ? 'User *' : 'Utilisateur *';
  String get scopeRequired => isEnglish ? 'Scope *' : 'Perimetre *';
  String get wholeCompany => isEnglish ? 'Whole company' : 'Toute la societe';
  String get permissions => isEnglish ? 'Permissions' : 'Permissions';
  String get viewTasks => isEnglish ? 'View tasks' : 'Voir les taches';
  String get assignTasks => isEnglish ? 'Assign tasks' : 'Affecter des taches';
  String get validateTasks =>
      isEnglish ? 'Validate tasks' : 'Valider les taches';
  String get manageProjects =>
      isEnglish ? 'Manage projects' : 'Gerer les projets';
  String get viewEvaluations =>
      isEnglish ? 'View evaluations' : 'Voir les evaluations';
  String get reviewEvaluations =>
      isEnglish ? 'Review evaluations' : 'Revoir les evaluations';
  String get productivityEvents => isEnglish ? 'Events' : 'Evenements';
  String get productivityRules => isEnglish ? 'Rules' : 'Regles';
  String get productivityScore =>
      isEnglish ? 'Productivity score' : 'Score de productivite';
  String get productivityScoreDescription => isEnglish
      ? 'Based on tasks, projects, mail and validations.'
      : 'Base sur les taches, projets, courriers et validations.';
  String get noProductivityEvents => isEnglish
      ? 'No productivity event is available.'
      : 'Aucun evenement de productivite disponible.';
  String get noProductivityRules => isEnglish
      ? 'No calculation rule is available.'
      : 'Aucune regle de calcul disponible.';
  String get activity => isEnglish ? 'Activity' : 'Activite';
  String get event => isEnglish ? 'Event' : 'Evenement';
  String get rule => isEnglish ? 'Rule' : 'Regle';
  String get points => isEnglish ? 'pts' : 'pts';
  String get productivityLoadError => isEnglish
      ? 'Unable to load productivity.'
      : 'Impossible de charger la productivite.';
  String get filterActivityLog =>
      isEnglish ? 'Filter activity log' : 'Filtrer le journal';
  String get module => isEnglish ? 'Module' : 'Module';
  String get action => isEnglish ? 'Action' : 'Action';
  String get startDate =>
      isEnglish ? 'Start date (YYYY-MM-DD)' : 'Date de debut (YYYY-MM-DD)';
  String get endDate =>
      isEnglish ? 'End date (YYYY-MM-DD)' : 'Date de fin (YYYY-MM-DD)';
  String allItems(String label) =>
      isEnglish ? 'All $label' : 'Tous les ${label.toLowerCase()}';
  String get activityDetails =>
      isEnglish ? 'Activity details' : 'Detail de l activite';
  String get messageLabel => isEnglish ? 'Message' : 'Message';
  String get dateLabel => isEnglish ? 'Date' : 'Date';
  String get actionLabel => isEnglish ? 'Action' : 'Action';
  String get moduleLabel => isEnglish ? 'Module' : 'Module';
  String get identifier => isEnglish ? 'Identifier' : 'Identifiant';
  String get associatedData =>
      isEnglish ? 'Associated data' : 'Donnees associees';
  String get activityLogHeading =>
      isEnglish ? 'Activity log' : 'Journal d activite';
  String get activityLogPageDescription => isEnglish
      ? 'Review important actions performed in your company.'
      : 'Retrouvez les actions importantes realisees dans votre entreprise.';
  String get searchActivity => isEnglish
      ? 'Search an action or a user...'
      : 'Rechercher une action ou un utilisateur...';
  String get filter => isEnglish ? 'Filter' : 'Filtrer';
  String get all => isEnglish ? 'All' : 'Tous';
  String get recentActivities =>
      isEnglish ? 'Recent activities' : 'Activites recentes';
  String activityCount(int count) => isEnglish
      ? '$count event${count == 1 ? '' : 's'}'
      : '$count evenement${count == 1 ? '' : 's'}';
  String get noActivityMatch => isEnglish
      ? 'No activity matches the filters.'
      : 'Aucune activite ne correspond aux filtres.';
  String get activityLoadError => isEnglish
      ? 'Unable to load the activity log.'
      : 'Impossible de charger le journal.';
  String get unknownUser => isEnglish ? 'Unknown user' : 'Utilisateur inconnu';
  String get userEntity => isEnglish ? 'User' : 'Utilisateur';
  String get projectEntity => isEnglish ? 'Project' : 'Projet';
  String get projectCreated => isEnglish ? 'Project created.' : 'Projet cree.';
  String get projectUpdated =>
      isEnglish ? 'Project updated.' : 'Projet mis a jour.';
  String get projectDeleted =>
      isEnglish ? 'Project deleted.' : 'Projet supprime.';
  String get projectStatusUpdated =>
      isEnglish ? 'Project status updated.' : 'Statut du projet mis a jour.';
  String get projectLoadError => isEnglish
      ? 'Unable to load projects.'
      : 'Impossible de charger les projets.';
  String get taskPeriod => isEnglish ? 'Task period' : 'Periode de la tache';
  String get startTime => isEnglish ? 'Start time' : 'Heure de debut';
  String get endTime => isEnglish ? 'End time' : 'Heure de fin';
  String get invalidDateRange => isEnglish
      ? 'The end must be after the start.'
      : 'La fin doit etre apres le debut.';
  String get addSubtask =>
      isEnglish ? 'Add a subtask' : 'Ajouter une sous-tache';
  String get addMemberTitle => isEnglish ? 'Add a member' : 'Ajouter un membre';
  String get roleInProject =>
      isEnglish ? 'Project role' : 'Role dans le projet';
  String get managerRole => isEnglish ? 'Manager' : 'Manager';
  String get reviewerRole => isEnglish ? 'Reviewer' : 'Evaluateur';
  String get contributorRole => isEnglish ? 'Contributor' : 'Contributeur';
  String get observerRole => isEnglish ? 'Observer' : 'Observateur';
  String get memberAdded => isEnglish ? 'Member added.' : 'Membre ajoute.';
  String get removeMemberTitle =>
      isEnglish ? 'Remove this member?' : 'Retirer ce membre ?';
  String get removeMemberMessage => isEnglish
      ? 'The member will no longer be associated with this project.'
      : 'Le membre ne sera plus associe a ce projet.';
  String get memberRemoved => isEnglish ? 'Member removed.' : 'Membre retire.';
  String get memberRoleTitle => isEnglish ? 'Member role' : 'Role du membre';
  String get roleUpdated => isEnglish ? 'Role updated.' : 'Role mis a jour.';
  String get removeLabel => isEnglish ? 'Remove' : 'Retirer';
  String get deleteProjectTitle =>
      isEnglish ? 'Delete project?' : 'Supprimer le projet ?';
  String get irreversibleAction => isEnglish
      ? 'This action cannot be undone.'
      : 'Cette action est irreversible.';
  String get taskEntity => isEnglish ? 'Task' : 'Tache';
  String get attachment => isEnglish ? 'Attachment' : 'Piece jointe';
  String get rename => isEnglish ? 'Rename' : 'Renommer';
  String get loadMoreFiles =>
      isEnglish ? 'Load more files' : 'Charger plus de fichiers';
  String get viewMoreComments =>
      isEnglish ? 'View more comments' : 'Voir plus de commentaires';
  String get pendingClosureReport => isEnglish
      ? 'Report pending until the task is completed.'
      : 'Rapport en attente de fin de tache.';
  String get reviewNote => isEnglish ? 'Review note' : 'Note de revue';
  String commentsDisplayed(int count) => isEnglish
      ? '$count comment(s) displayed'
      : '$count commentaire(s) affiche(s)';
  String get noComments => isEnglish ? 'No comments' : 'Aucun commentaire';
  String get noCommentsDescription => isEnglish
      ? 'Comments for this task will appear here.'
      : 'Les commentaires de cette tache apparaitront ici.';
  String get loadMore => isEnglish ? 'Load more' : 'Charger plus';
  String get closureReportRequired => isEnglish
      ? 'The closure report is required.'
      : 'Le rapport de cloture est obligatoire.';
  String get closureReportSubmitted =>
      isEnglish ? 'Report submitted.' : 'Rapport soumis.';
  String get closureReportValidated =>
      isEnglish ? 'Report validated.' : 'Rapport valide.';
  String get closureReportRejected =>
      isEnglish ? 'Report rejected.' : 'Rapport rejete.';
  String get rejectionReason =>
      isEnglish ? 'Rejection reason' : 'Motif du rejet';
  String get note => isEnglish ? 'Note' : 'Note';
  String get taskReassigned =>
      isEnglish ? 'Task reassigned.' : 'Tache reassignee.';
  String get taskDeleted => isEnglish ? 'Task deleted.' : 'Tache supprimee.';
  String get taskUpdated => isEnglish ? 'Task updated.' : 'Tache mise a jour.';
  String get commentUpdated =>
      isEnglish ? 'Comment updated.' : 'Commentaire modifie.';
  String get commentDeleted =>
      isEnglish ? 'Comment deleted.' : 'Commentaire supprime.';
  String get fileRenamed => isEnglish ? 'File renamed.' : 'Fichier renomme.';
  String get fileDeleted => isEnglish ? 'File deleted.' : 'Fichier supprime.';
  String get deleteTaskTitle =>
      isEnglish ? 'Delete task?' : 'Supprimer la tache ?';
  String get deleteCommentTitle =>
      isEnglish ? 'Delete comment?' : 'Supprimer le commentaire ?';
  String get deleteFileTitle =>
      isEnglish ? 'Delete file?' : 'Supprimer le fichier ?';
  String get editComment =>
      isEnglish ? 'Edit comment' : 'Modifier le commentaire';
  String get renameFile => isEnglish ? 'Rename file' : 'Renommer le fichier';
  String get courrierEntity => isEnglish ? 'Mail' : 'Courrier';
  String get evaluationEntity => isEnglish ? 'Evaluation' : 'Evaluation';
  String get companyEntity => isEnglish ? 'Company' : 'Entreprise';
  String get filterQuestions =>
      isEnglish ? 'Filter questions' : 'Filtrer les questions';
  String get allLanguages => isEnglish ? 'All languages' : 'Toutes les langues';
  String get addQuestion => isEnglish ? 'Add question' : 'Ajouter une question';
  String get editQuestion =>
      isEnglish ? 'Edit question' : 'Modifier la question';
  String get questionFormDescription => isEnglish
      ? 'The question will be proposed according to the selected position and scope.'
      : 'La question sera proposee selon le poste et le rattachement choisis.';
  String get targetPosition =>
      isEnglish ? 'Target position *' : 'Poste cible *';
  String get questionRequired => isEnglish ? 'Question *' : 'Question *';
  String get optionalDepartment =>
      isEnglish ? 'Department (optional)' : 'Departement (facultatif)';
  String get optionalService =>
      isEnglish ? 'Service (optional)' : 'Service (facultatif)';
  String get allDepartments =>
      isEnglish ? 'All departments' : 'Tous les departements';
  String get allServices => isEnglish ? 'All services' : 'Tous les services';
  String get questionFieldsRequired => isEnglish
      ? 'The position and question are required.'
      : 'Le poste et la question sont obligatoires.';
  String get deleteQuestionTitle =>
      isEnglish ? 'Delete question?' : 'Supprimer la question ?';
  String get deleteQuestionMessage => isEnglish
      ? 'This will remove the question from upcoming evaluations.'
      : 'Cette action supprimera la question des prochaines evaluations.';
  String get configuredQuestions =>
      isEnglish ? 'Configured questions' : 'Questions configurees';
  String questionCount(int count) => isEnglish
      ? '$count question${count == 1 ? '' : 's'}'
      : '$count question${count == 1 ? '' : 's'}';
  String get noQuestionMatch => isEnglish
      ? 'No question matches the filters.'
      : 'Aucune question ne correspond aux filtres.';
  String get questionsLoadError => isEnglish
      ? 'Unable to load questions.'
      : 'Impossible de charger les questions.';
  String get searchQuestion => isEnglish
      ? 'Search a question or a position...'
      : 'Rechercher une question ou un poste...';
  String get filterCriteria =>
      isEnglish ? 'Filter criteria' : 'Filtrer les criteres';
  String get allCriteria => isEnglish ? 'All criteria' : 'Tous les criteres';
  String get activeCriteria => isEnglish ? 'Active' : 'Actifs';
  String get inactiveCriteria => isEnglish ? 'Inactive' : 'Inactifs';
  String get activeStatus => isEnglish ? 'Active' : 'Actif';
  String get criterionLoadError => isEnglish
      ? 'Unable to load criteria.'
      : 'Impossible de charger les criteres.';
  String get criteriaHeading =>
      isEnglish ? 'Evaluation criteria' : 'Criteres d evaluation';
  String get criteriaPageDescription => isEnglish
      ? 'Configure the grid managers use to rate evaluations.'
      : 'Configurez la grille utilisee par les responsables pour noter les evaluations.';
  String get searchCriteria => isEnglish
      ? 'Search a criterion or a category...'
      : 'Rechercher un critere ou une categorie...';
  String get configuredCriteria =>
      isEnglish ? 'Configured criteria' : 'Criteres configures';
  String criterionCount(int count) => isEnglish
      ? '$count criterion${count == 1 ? '' : 'a'}'
      : '$count critere${count == 1 ? '' : 's'}';
  String get noCriterionMatch => isEnglish
      ? 'No criterion matches the filters.'
      : 'Aucun critere ne correspond aux filtres.';
  String get addCriterion => isEnglish ? 'Add criterion' : 'Ajouter un critere';
  String get editCriterion =>
      isEnglish ? 'Edit criterion' : 'Modifier le critere';
  String get deleteCriterionTitle =>
      isEnglish ? 'Delete criterion?' : 'Supprimer le critere ?';
  String get deleteCriterionMessage => isEnglish
      ? 'This criterion will no longer be proposed in new evaluations.'
      : 'Ce critere ne sera plus propose dans les nouvelles evaluations.';
  String get criterionFormDescription => isEnglish
      ? 'Define the criterion used by the manager.'
      : 'Definissez le critere utilise par le superieur hierarchique.';
  String get labelRequired => isEnglish ? 'Label *' : 'Libelle *';
  String get category => isEnglish ? 'Category' : 'Categorie';
  String get maxScore => isEnglish ? 'Maximum score' : 'Score maximum';
  String get sortOrder => isEnglish ? 'Order' : 'Ordre';
  String get criterionActive =>
      isEnglish ? 'Active criterion' : 'Critere actif';
  String get criterionFieldsRequired =>
      isEnglish ? 'The label is required.' : 'Le libelle est obligatoire.';
  String get evaluationsListDescription => isEnglish
      ? 'Review evaluations visible according to your role.'
      : 'Consultez les evaluations visibles selon votre role.';
  String get filterEvaluations =>
      isEnglish ? 'Filter evaluations' : 'Filtrer les evaluations';
  String get evaluationLoadError => isEnglish
      ? 'Unable to load evaluations.'
      : 'Impossible de charger les evaluations.';
  String get evaluationCreatedWithoutId => isEnglish
      ? 'Evaluation created without an identifier.'
      : 'Evaluation creee sans identifiant.';
  String get allEvaluations => isEnglish ? 'All' : 'Tous';
  String get evaluationNotStarted =>
      isEnglish ? 'Not started' : 'Non commencees';
  String get evaluationInProgress => isEnglish ? 'In progress' : 'En cours';
  String get managerReviewPending =>
      isEnglish ? 'Manager review' : 'Avis superieur';
  String get aiScoreAvailable =>
      isEnglish ? 'AI score available' : 'Score IA disponible';
  String get managerReviewed => isEnglish ? 'Reviewed' : 'Avis soumis';
  String get adminReviewPending =>
      isEnglish ? 'Final validation' : 'Validation finale';
  String get completedEvaluations => isEnglish ? 'Completed' : 'Terminees';
  String get noEvaluationMatch => isEnglish
      ? 'No evaluation matches the filters.'
      : 'Aucune evaluation ne correspond aux filtres.';
  String get unknownEvaluationUser => isEnglish ? 'User' : 'Utilisateur';
  String get evaluationDetailLoadError => isEnglish
      ? 'Unable to load evaluation details.'
      : 'Impossible de charger le detail de evaluation.';
  String get noCriteriaAvailable => isEnglish
      ? 'No rating criterion is available.'
      : 'Aucun critere de notation n est disponible.';
  String get criterion => isEnglish ? 'Criterion' : 'Critere';
  String get answersSent => isEnglish ? 'Answers sent.' : 'Reponses envoyees.';
  String get managerFeedbackSaved =>
      isEnglish ? 'Manager feedback saved.' : 'Avis du superieur enregistre.';
  String get evaluationValidated =>
      isEnglish ? 'Evaluation validated.' : 'Evaluation validee.';
  String get managerRating =>
      isEnglish ? 'Manager rating' : 'Notation du superieur';
  String get rateEachCriterion => isEnglish
      ? 'Rate each criterion before submitting your review.'
      : 'Notez chaque critere avant de soumettre votre avis.';
  String get criterionComment =>
      isEnglish ? 'Comment on this criterion' : 'Commentaire sur ce critere';
  String get globalComment =>
      isEnglish ? 'Overall comment' : 'Commentaire global';
  String get submitRating =>
      isEnglish ? 'Submit rating' : 'Soumettre la notation';
  String get finalAdminValidation =>
      isEnglish ? 'Final admin validation' : 'Validation finale admin';
  String get finalScoreOutOf100 =>
      isEnglish ? 'Final score out of 100' : 'Note finale sur 100';
  String get validationComment =>
      isEnglish ? 'Validation comment' : 'Commentaire de validation';
  String get aiAnalysis => isEnglish ? 'AI analysis' : 'Analyse IA';
  String get answersReadyForAnalysis => isEnglish
      ? 'Answers are ready for analysis.'
      : 'Les reponses sont pretes pour analyse.';
  String get launchAnalysis =>
      isEnglish ? 'Launch analysis' : 'Lancer l analyse';
  String get aiScoreGenerated =>
      isEnglish ? 'AI score generated.' : 'Score IA genere.';
  String get managerOpinion =>
      isEnglish ? 'Manager review' : 'Avis du superieur';
  String get managerOpinionDescription => isEnglish
      ? 'Add the manager score and comment.'
      : 'Ajoutez le score et le commentaire du superieur.';
  String get giveOpinion => isEnglish ? 'Give feedback' : 'Donner un avis';
  String get finalValidation =>
      isEnglish ? 'Final validation' : 'Validation finale';
  String get finalValidationDescription => isEnglish
      ? 'Validate the file after the previous steps.'
      : 'Validez le dossier apres les etapes precedentes.';
  String get validateEvaluation =>
      isEnglish ? 'Validate evaluation' : 'Valider evaluation';
  String get currentStep => isEnglish ? 'Current step' : 'Etape actuelle';
  String get managerOpinions =>
      isEnglish ? 'Manager reviews' : 'Avis des superieurs';
  String get noComment => isEnglish ? 'No comment' : 'Aucun commentaire';
  String get answerBeforeContinue => isEnglish
      ? 'Answer this question before continuing.'
      : 'Repondez a cette question avant de continuer.';
  String get productivityScoreLabel =>
      isEnglish ? 'Productivity' : 'Productivite';
  String get aiLabel => isEnglish ? 'AI' : 'IA';
  String get managerLabel => isEnglish ? 'Manager' : 'Superieur';
  String get adminLabel => isEnglish ? 'Admin' : 'Admin';
  String get finalLabel => isEnglish ? 'Final' : 'Final';
  String get reviewAnswers =>
      isEnglish ? 'Review answers' : 'Revision des reponses';
  String get reviewAnswersDescription => isEnglish
      ? 'Review your answers before submitting them.'
      : 'Relisez vos reponses avant de les soumettre.';
  String get questionsAndAnswers =>
      isEnglish ? 'Questions and answers' : 'Questions et reponses';
  String get answersAlreadySubmitted =>
      isEnglish ? 'Answers already submitted.' : 'Reponses deja soumises.';
  String get question => isEnglish ? 'Question' : 'Question';
  String get ofLabel => isEnglish ? 'of' : 'sur';
  String get addSupervisor =>
      isEnglish ? 'Add supervisor' : 'Ajouter un superviseur';
  String get editSupervisor =>
      isEnglish ? 'Edit supervisor' : 'Modifier le superviseur';
  String get supervisorFormDescription => isEnglish
      ? 'Assign a scope and the actions this supervisor can perform.'
      : 'Attribuez un perimetre et les actions autorisees.';
  String get departmentRequired => isEnglish ? 'Department *' : 'Departement *';
  String get serviceRequired => isEnglish ? 'Service *' : 'Service *';
  String get configuredAssignments =>
      isEnglish ? 'Configured assignments' : 'Rattachements configures';
  String supervisorCount(int count) => isEnglish
      ? '$count supervisor${count == 1 ? '' : 's'}'
      : '$count superviseur${count == 1 ? '' : 's'}';
  String get supervisorsLoadError => isEnglish
      ? 'Unable to load supervisors.'
      : 'Impossible de charger les superviseurs.';
}

class LocalizationScope extends InheritedWidget {
  const LocalizationScope({
    super.key,
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  AppLocalizations get value => AppLocalizations(language);

  @override
  bool updateShouldNotify(LocalizationScope oldWidget) =>
      language != oldWidget.language;
}

typedef _LocalizationScope = LocalizationScope;
