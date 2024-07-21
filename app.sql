
-- USERS
CREATE TABLE [users] (
  [id] INT,
  [name] TEXT,
  [avatar] TEXT,
  [email] TEXT,
  [biography] TEXT,
  [position] TEXT,
  [country] TEXT,
  [status] TEXT
);

INSERT INTO [users] ([id],[name],[avatar],[email],[biography],[position],[country],[status])
VALUES
(1,'Neil Sims','neil-sims.png','neil.sims@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Front-end developer','United States','Active'),
(2,'Roberta Casas','roberta-casas.png','roberta.casas@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Designer','Spain','Active'),
(3,'Michael Gough','michael-gough.png','michael.gough@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','React developer','United Kingdom','Active'),
(4,'Jese Leos','jese-leos.png','jese.leos@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Marketing','United States','Active'),
(5,'Bonnie Green','bonnie-green.png','bonnie.green@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','UI/UX Engineer','Australia','Offline'),
(6,'Thomas Lean','thomas-lean.png','thomas.lean@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Vue developer','Germany','Active'),
(7,'Helene Engels','helene-engels.png','helene.engels@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Product owner','Canada','Active'),
(8,'Lana Byrd','lana-byrd.png','lana.byrd@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Designer','United States','Active'),
(9,'Leslie Livingston','leslie-livingston.png','leslie.livingston@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Web developer','France','Offline'),
(10,'Robert Brown','robert-brown.png','robert.brown@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Laravel developer','Russia','Active'),
(11,'Neil Sims','neil-sims.png','neil.sims@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Front-end developer','United States','Active'),
(12,'Roberta Casas','roberta-casas.png','roberta.casas@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Designer','Spain','Active'),
(13,'Michael Gough','michael-gough.png','michael.gough@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','React developer','United Kingdom','Active'),
(14,'Jese Leos','jese-leos.png','jese.leos@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Marketing','United States','Active'),
(15,'Bonnie Green','bonnie-green.png','bonnie.green@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','UI/UX Engineer','Australia','Offline'),
(16,'Thomas Lean','thomas-lean.png','thomas.lean@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Vue developer','Germany','Active'),
(17,'Helene Engels','helene-engels.png','helene.engels@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Product owner','Canada','Active'),
(18,'Lana Byrd','lana-byrd.png','lana.byrd@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Designer','United States','Active'),
(19,'Leslie Livingston','leslie-livingston.png','leslie.livingston@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Web developer','France','Offline'),
(20,'Robert Brown','robert-brown.png','robert.brown@flowbite.com','I love working with React and Flowbites to create efficient and user-friendly interfaces. In my spare time, I enjoys baking, hiking, and spending time with my family.','Laravel developer','Russia','Active');

-- SESSIONS
CREATE TABLE sessions (
    session_id INTEGER PRIMARY KEY,
    user_id INTEGER NULL,

    CONSTRAINT fk_column
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE
);

CREATE TABLE [products] (
  [name] TEXT,
  [category] TEXT,
  [technology] TEXT,
  [id] INT,
  [description] TEXT,
  [price] TEXT,
  [discount] TEXT
);

INSERT INTO [products] ([name],[category],[technology],[id],[description],[price],[discount])
VALUES
('Education Dashboard','Html templates','Angular',194556,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',623232,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','10%'),
('Education Dashboard','Html templates','Angular',194356,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',323323,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',99428562,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','25%'),
('Education Dashboard','Html templates','Angular',1942562,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','10%'),
('React UI Kit','Html templates','React JS',6233782,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',1928516,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',5233323,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',1918157,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('Education Dashboard','Html templates','Angular',1914856,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','30%'),
('React UI Kit','Html templates','React JS',6332932,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',194526,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',6232323,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',1943567,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','5%'),
('React UI Kit','Html templates','React JS',3233232,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',994856,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('Education Dashboard','Html templates','Angular',194256,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',623378,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','50%'),
('Education Dashboard','Html templates','Angular',192856,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',523323,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No'),
('Education Dashboard','Html templates','Angular',191857,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','10%'),
('Education Dashboard','Html templates','Angular',914856,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$149','No'),
('React UI Kit','Html templates','React JS',6333293,'Start developing with an open-source library of over 450+ UI components, sections, and pages built with the utility classes from Tailwind CSS and designed in Figma.','$129','No');
