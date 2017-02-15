# Étude comparative d'algorithmes d'autoscaling

Ce répertoire contient les codes des applications ayant permis l'exécution des expériences de notre étude comparative d'algorithmes d'autoscaling. Les répertoires contiennent les codes suivants~:

* http_loader : service web permettant de simuler une charge sur la plateforme. Il consiste en un calcul très mal optimisé de nombres premiers. Cette application joue le rôle de l'_application cliente_.
* http_charger : application permettant d'inonder l'application de test. Il permet de simuler des scénarios d’augmentation et de diminution de la charge sur une application. Cette application joue le rôle d'utilisateur de l'_application cliente_.
* autoscaling : partie logique de notre application. C'est ici que seront implémentés les différents algorithmes que nous voulons tester. Cette application est le cœur de notre _solution_.
