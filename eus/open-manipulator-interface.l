
(require :open-manipulator "package://open_manipulator_eus/eus/open-manipulator.l")
(require :robot-interface "package://pr2eus/robot-interface.l")
(ros::load-ros-manifest "control_msgs")
(ros::load-ros-manifest "open_manipulator_msgs")

(defclass open-manipulator-interface :super robot-interface :slots nil)

(defmethod open-manipulator-interface
           (:init (&rest args)
            (send-super* :init :robot open-manipulator-robot :base-frame-id "link1"
             :groupname "open-manipulator_interface"
             :namespace "mikata_arm" args)
            (send self :add-controller :arm-controller))
  (:state (&rest args)
   (send-super* :state
    (if (member :wait-until-update args)
        args
        (append args (list :wait-until-update t)))))
  (:arm-controller nil
   (list
    (list (cons :controller-action "arm_controller/follow_joint_trajectory")
          (cons :controller-state "arm_controller/state")
          (cons :action-type control_msgs::followjointtrajectoryaction)
          (cons :joint-names '("joint1" "joint2" "joint3" "joint4" "joint5" "joint6")))))
  (:default-controller nil
   (send self :arm-controller))
  (:move-gripper (pos)
   (let ((srv (format nil "~A/goal_tool_control" namespace))
         (req (instance open_manipulator_msgs::SetJointPositionRequest :init)))
     (send req :joint_position :joint_name (list "gripper"))
     (send req :joint_position :position (list pos))
     (ros::wait-for-service srv)
     (ros::service-call srv req)))
  (:start-grasp ()
   (send self :move-gripper -0.7))
  (:stop-grasp ()
   (send self :move-gripper 0.7))
)

(defun open-manipulator-init (&optional (create-viewer))
  (unless (ros::ok) (ros::roseus "open-manipulator_eus_interface"))
  (unless (boundp '*open-manipulator*) (setq *open-manipulator* (open-manipulator)))
  (unless (boundp '*ri*) (setq *ri* (instance open-manipulator-interface :init)))
  (ros::spin-once)
  (send *ri* :spin-once)
  (send *open-manipulator* :angle-vector (send *ri* :state :potentio-vector))
  (when create-viewer (objects (list *open-manipulator*))))
