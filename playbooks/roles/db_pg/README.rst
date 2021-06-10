Role to provision DB instances and users on PostgreSQL DB

**Role Variables**

.. zuul:rolevar:: login

   Dictionary with `host`, `username`, `password` and `database` keys used for connecting to the DB cluster (login_XXX variables)

.. zuul:rolevar:: instances

   List with databases to be created ([{name: 'n1'}, {name: 'n2'}].

.. zuul:rolevar:: users

   List of user dicts to be created.
